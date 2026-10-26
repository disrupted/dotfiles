-- Snacks picker sources backed by atlas.nvim's pull request and issue
-- providers.
--
-- The finders intentionally go through Atlas instead of `snacks.gh.api` so
-- both UIs share Atlas' on-disk HTTP cache (`providers.github.cache_ttl`).
-- Typing filters locally; only the finder (toggles/refresh) hits GitHub.

local icons = require('conf.icons')

local M = {}

-- Snacks' default picker keymaps assume file/location items. Atlas PR and issue
-- items have neither, so disable the inherited mappings that would otherwise
-- be no-ops (or warn about unsupported live search).
local DISABLED_SOURCE_KEYS = {
    '<A-f>', -- toggle_follow
    '<A-h>', -- toggle_hidden
    '<A-i>', -- toggle_ignored
    '<C-g>', -- toggle_live / print_path
    '<C-q>', -- qflist
    '<C-s>', -- edit_split
    '<C-t>', -- tab
    '<C-v>', -- edit_vsplit
    '<S-CR>', -- pick_win / jump
}

---@param keys table<string, false|string|table>
local function disable_source_keys(keys)
    for _, key in ipairs(DISABLED_SOURCE_KEYS) do
        keys[key] = false
    end
end

---@class conf.snacks.atlas.Filter
---@field key string lhs keymap
---@field icon string icon shown in the picker's `{flags}` title slot
---@field desc string human readable description used by keymaps
---@field qualifier string GitHub search qualifier

---@type table<string, conf.snacks.atlas.Filter>
local FILTERS = {
    mine = {
        key = '<A-a>',
        icon = icons.misc.user,
        desc = 'Authored or assigned to me',
        qualifier = 'involves:@me',
    },
    review_requested = {
        key = '<A-r>',
        icon = icons.git.review,
        desc = 'Review requested',
        qualifier = 'review-requested:@me',
    },
}

local FILTER_NAMES = vim.tbl_keys(FILTERS)
table.sort(FILTER_NAMES)

---@type table<string, PullsStateFilter[]>
local STATE_FILTERS = {
    open = { 'open' },
    closed = { 'merged', 'declined' },
    merged = { 'merged' },
    all = { 'open', 'merged', 'declined' },
}

---@param state string|nil
---@return string, string
local function state_icon(state)
    local atlas_icons = require('atlas.ui.shared.icons')
    local name = state == 'draft' and 'draft_pr'
        or state == 'merged' and 'merged_pr'
        or state == 'declined' and 'declined_pr'
        or 'pr'
    return atlas_icons.get(name)
end

---@param pr PullRequest
---@param provider PullsProvider
---@return snacks.picker.finder.Item
local function entry(pr, provider)
    return {
        text = table.concat({
            '#' .. tostring(pr.id),
            pr.title,
            pr.author and pr.author.username or '',
            pr.repo_full_name or '',
        }, ' '),
        item = pr,
        provider = provider,
    }
end

---@param provider PullsProvider
---@param repo AtlasTarget
---@param opts table
---@return AtlasPullsViewConfig
local function view_for(provider, repo, opts)
    local view
    local search = vim.trim(opts.search or '')

    if search ~= '' then
        -- Explicit searches are still scoped to the current repository, like
        -- `gh pr list --search`.
        view = provider.repository_view(repo)
        view.search = vim.trim(view.search .. ' ' .. search)
    else
        -- Prefer Atlas' configured current-repo view when present. Reusing its
        -- exact search string means the dashboard and this picker hit the same
        -- cache entry.
        for _, candidate in ipairs(provider.views()) do
            if candidate.current_repo then
                view = vim.deepcopy(candidate)
                -- Resolve the repository ourselves instead of letting Atlas
                -- call `git` again against the process cwd.
                view.current_repo = nil
                view.search = vim.trim(
                    ('repo:%s %s'):format(repo.repo_full_name, view.search or '')
                )
                break
            end
        end
        view = view or provider.repository_view(repo)
    end

    local qualifiers = {}
    for _, name in ipairs(FILTER_NAMES) do
        if opts[name] then
            qualifiers[#qualifiers + 1] = FILTERS[name].qualifier
        end
    end
    if #qualifiers > 0 then
        view.search =
            vim.trim((view.search or '') .. ' ' .. table.concat(qualifiers, ' '))
    end

    view._states = opts.states
        or STATE_FILTERS[opts.state or 'open']
        or STATE_FILTERS.open
    return view
end

---@param opts table
---@param ctx snacks.picker.finder.ctx
---@return snacks.picker.finder.result
local function finder(opts, ctx)
    local Snacks = require('snacks')
    local cwd = ctx:cwd()

    -- `require("atlas")` also lets laze load/configure the plugin on first use
    -- if it has not been opened through `:Atlas` yet. Do it before entering the
    -- async finder, where Neovim API calls would be disallowed.
    local ok, atlas_err = pcall(require, 'atlas')
    if not ok then
        Snacks.notify.error('atlas.nvim is unavailable: ' .. tostring(atlas_err))
        return {}
    end
    local git = require('atlas.core.git')

    ---@async
    return function(cb)
        local cancelled = false
        local current

        ctx.async:on('abort', function()
            cancelled = true
            if current and current.cancel then
                pcall(current.cancel)
            end
        end)

        ---@param start fun(done: fun(value: any, err: any)): { cancel: fun() }|nil
        ---@return any, any
        local function await(start)
            local done = false
            local value, err
            -- Atlas uses Neovim APIs (vim.fn, nvim_buf_get_name, ...) for git
            -- and cache work. Run that on the main loop instead of the async
            -- fast-event context.
            vim.schedule(function()
                if cancelled then
                    return
                end
                local started, handle = pcall(start, function(result, failure)
                    done = true
                    value, err = result, failure
                    ctx.async:resume()
                end)
                if not started then
                    done = true
                    err = tostring(handle)
                    ctx.async:resume()
                    return
                end
                if not done then
                    current = handle
                end
            end)
            if not done then
                ---@diagnostic disable-next-line: await-in-sync
                ctx.async:suspend()
            end
            current = nil
            if cancelled then
                error('aborted', 0)
            end
            return value, err
        end

        local repo, repo_err = await(function(done)
            return git.local_repository(cwd, done)
        end)
        if not repo then
            Snacks.notify.warn(
                repo_err or 'No supported Git repository found',
                { title = 'Pull Requests' }
            )
            return
        end

        -- Loading provider modules and building the view can create namespaces
        -- and touch other Neovim APIs, so keep this on the main loop too.
        local result, setup_err = await(function(done)
            local config = require('atlas.config')
            if not config.provider_options(repo.provider) then
                done(nil, 'Atlas provider not configured: ' .. tostring(repo.provider))
                return
            end

            local providers = require('atlas.providers')
            local provider = providers.load(repo.provider, 'pulls')
            if not provider then
                done(
                    nil,
                    'Pull requests are not supported for ' .. tostring(repo.provider)
                )
                return
            end
            ---@cast provider PullsProvider

            if provider.id ~= 'github' then
                local enabled = false
                for _, name in ipairs(FILTER_NAMES) do
                    enabled = enabled or opts[name]
                end
                if enabled then
                    done(nil, 'Pull request filters are only implemented for GitHub')
                    return
                end
            end

            local force_refresh = opts.atlas_force_refresh == true
            opts.atlas_force_refresh = nil

            local view = view_for(provider, repo, opts)
            return provider.capabilities.core.fetch_pullrequests(view, {
                force_refresh = force_refresh,
                pagelen = opts.pagelen or 50,
            }, function(page, errors)
                done({
                    provider = provider,
                    view = view,
                    page = page,
                    errors = errors,
                }, nil)
            end)
        end)
        if not result then
            Snacks.notify.warn(
                setup_err or 'Unable to load Atlas pull request provider',
                { title = 'Pull Requests' }
            )
            return
        end

        local provider = result.provider
        local view = result.view
        local page = result.page
        local fetch_errors = result.errors
        local items = page and page.items or {}
        local errors = type(fetch_errors) == 'table' and fetch_errors
            or (fetch_errors and { tostring(fetch_errors) })
            or {}
        if #errors > 0 then
            local message = table.concat(errors, '; ')
            if #items == 0 then
                Snacks.notify.error(message, { title = 'Pull Requests' })
                return
            end
            Snacks.notify.warn(message, { title = 'Pull Requests' })
        end

        local allowed = {}
        for _, state in ipairs(view._states) do
            allowed[state] = true
        end

        for _, pr in ipairs(items) do
            -- GitHub's `is:open` includes drafts; Atlas maps them to `draft`.
            local state = pr.state == 'draft' and 'open' or pr.state
            if allowed[state] then
                cb(entry(pr, provider))
            end
        end
    end
end

---@param pr PullRequest
---@param details PullRequestDetails|nil
---@return string[]
local function preview_lines(pr, details)
    local presentation = require('atlas.pulls.ui.presentation')
    local utils = require('atlas.ui.shared.utils')

    local lines = {
        ('# #%s %s'):format(tostring(pr.id), pr.title),
        '',
        ('**State:** %s  **Author:** @%s'):format(
            pr.state,
            presentation.user_handle(pr.author)
        ),
        ('**Branches:** `%s` -> `%s`'):format(pr.source.branch, pr.destination.branch),
        ('**Updated:** %s'):format(utils.relative_time(pr.updated_on)),
    }

    if details then
        local assignees = vim.tbl_map(function(user)
            return '@' .. presentation.user_handle(user)
        end, details.assignees or {})
        local labels = vim.tbl_map(function(label)
            return label.name
        end, details.labels or {})

        if #assignees > 0 then
            lines[#lines + 1] = '**Assignees:** ' .. table.concat(assignees, ', ')
        end
        if #labels > 0 then
            lines[#lines + 1] = '**Labels:** ' .. table.concat(labels, ', ')
        end

        lines[#lines + 1] = ''
        lines[#lines + 1] = '---'
        lines[#lines + 1] = ''
        lines[#lines + 1] = '## Description'
        lines[#lines + 1] = ''
        vim.list_extend(
            lines,
            vim.split((details.description or ''):gsub('\r\n', '\n'), '\n', {
                plain = true,
            })
        )
    end

    return lines
end

---@param truncate fun(text: string, width: number): string
---@param title string
---@param max_width number
---@return string
local function flex_title(truncate, title, max_width)
    -- Snacks always gives the flexible spacer at least one column. Leave that
    -- column free so a truncated title cannot push the time column right.
    return truncate(title, math.max(max_width - 1, 1))
end

---@type snacks.picker.format
M.format = function(item)
    local pr = item.item
    local icon, icon_hl = state_icon(pr.state)
    local utils = require('atlas.ui.shared.utils')
    local Snacks = require('snacks')
    local align = Snacks.picker.util.align
    local truncate = Snacks.picker.util.truncate
    local title = pr.title

    local ret = {
        { icon .. ' ', icon_hl },
        { '#' .. tostring(pr.id) .. ' ', 'SnacksPickerDimmed' },
        {
            '',
            resolve = function(max_width)
                return { { flex_title(truncate, title, max_width) } }
            end,
        },
        {
            '',
            resolve = function(max_width)
                return { { (' '):rep(max_width) } }
            end,
        },
    }

    if pr.author and pr.author.username ~= '' then
        ret[#ret + 1] = { ' @' .. pr.author.username, 'SnacksPickerGitAuthor' }
    end
    ret[#ret + 1] = {
        ' ' .. align(utils.relative_time(pr.updated_on), 3, { align = 'right' }),
        'SnacksPickerGitDate',
    }
    -- Reserve two columns at the right edge (the list already adds a leading
    -- margin). Snacks strips this trailing whitespace after resolving the
    -- flexible spacer.
    ret[#ret + 1] = { '  ' }
    return ret
end

---@type snacks.picker.preview
M.preview = function(ctx)
    local pr = ctx.item.item
    local provider = ctx.item.provider
    ctx.preview:reset()
    ctx.preview:set_title(('#%s %s'):format(tostring(pr.id), pr.title))
    ctx.preview:set_lines(preview_lines(pr))
    ctx.preview:highlight({ ft = 'markdown' })

    if not provider then
        return
    end

    provider.capabilities.core.fetch_pullrequest(pr, nil, function(details, err)
        vim.schedule(function()
            if
                ctx.picker.closed
                or ctx.preview.item ~= ctx.item
                or not ctx.preview.win:valid()
            then
                return
            end
            if not details then
                ctx.preview:notify(
                    tostring(err or 'Failed to load pull request'),
                    'error',
                    { item = false }
                )
                return
            end
            ctx.preview:set_lines(preview_lines(pr, details))
            ctx.preview:highlight({ ft = 'markdown' })
        end)
    end)
end

---@param picker snacks.Picker
---@param item snacks.picker.finder.Item|nil
local function open_detail(picker, item)
    if not item then
        return
    end
    local pr = item.item
    local provider = item.provider
    picker:close()
    vim.schedule(function()
        require('atlas.pulls.ui.detail').open(pr, { provider = provider })
    end)
end

local toggles, actions = {}, {}
local input_keys, list_keys = {}, {}

for _, name in ipairs(FILTER_NAMES) do
    local filter = FILTERS[name]
    toggles[name] = { icon = filter.icon }
    input_keys[filter.key] = {
        'atlas_toggle_' .. name,
        mode = { 'n', 'i' },
        desc = filter.desc,
    }
    list_keys[filter.key] = {
        'atlas_toggle_' .. name,
        desc = filter.desc,
    }
    actions['atlas_toggle_' .. name] = function(picker)
        local enable = not picker.opts[name]
        for _, other in ipairs(FILTER_NAMES) do
            picker.opts[other] = (other == name and enable) or nil
        end
        picker.list:set_target()
        picker:find()
    end
end

actions.atlas_refresh = function(picker)
    picker.opts.atlas_force_refresh = true
    picker:find({ refresh = true })
end

actions.atlas_checkout = function(picker, item)
    if not item then
        return
    end
    local context = { provider = item.provider, pr = item.item }
    picker:close()
    require('atlas.pulls.actions').run('checkout', context, function(_, err)
        if err then
            require('snacks').notify.error('Checkout failed: ' .. tostring(err))
        end
    end)
end

input_keys['<C-o>'] = {
    'atlas_checkout',
    mode = { 'n', 'i' },
    desc = 'Checkout PR branch',
}
list_keys['<C-o>'] = {
    'atlas_checkout',
    desc = 'Checkout PR branch',
}
input_keys['<C-r>'] = {
    'atlas_refresh',
    mode = { 'n', 'i' },
    desc = 'Refresh from GitHub',
}
list_keys['<C-r>'] = {
    'atlas_refresh',
    desc = 'Refresh from GitHub',
}

disable_source_keys(input_keys)
disable_source_keys(list_keys)

---@type snacks.picker.Config
M.pr = {
    title = icons.git.github .. '  Pull Requests',
    finder = finder,
    format = M.format,
    preview = M.preview,
    confirm = open_detail,
    sort = { fields = { 'score:desc', 'idx' } },
    toggles = toggles,
    actions = actions,
    -- Typing filters the list locally; only toggles/refresh refetch.
    live = false,
    supports_live = false,
    show_delay = 0,
    win = {
        input = { keys = input_keys },
        list = { keys = list_keys },
        preview = {
            wo = {
                conceallevel = 3,
                concealcursor = 'nvic',
            },
        },
    },
}

-- Issues ---------------------------------------------------------------------

---@type table<string, conf.snacks.atlas.Filter>
local ISSUE_FILTERS = {
    assigned_me = {
        key = '<A-a>',
        icon = icons.misc.user,
        desc = 'Assigned to me',
        qualifier = 'assignee:@me',
    },
    created_me = {
        key = '<A-c>',
        icon = icons.misc.user_plus,
        desc = 'Created by me',
        qualifier = 'author:@me',
    },
    mentioned_me = {
        key = '<A-n>',
        icon = icons.git.review,
        desc = 'Mentions me',
        qualifier = 'mentions:@me',
    },
}

local ISSUE_FILTER_NAMES = vim.tbl_keys(ISSUE_FILTERS)
table.sort(ISSUE_FILTER_NAMES)

---@param status_id string|nil
---@return string, string
local function issue_state_icon(status_id)
    local utils = require('atlas.issues.ui.layouts.utils')
    return utils.state_icon(status_id)
end

---@param issue Issue
---@param provider IssuesProvider
---@return snacks.picker.finder.Item
local function issue_entry(issue, provider)
    ---@cast issue GitHubIssue
    return {
        text = table.concat({
            '#' .. tostring(issue.number or issue.key),
            issue.title,
            issue.reporter and issue.reporter.username or '',
            issue.repo_full_name or '',
        }, ' '),
        item = issue,
        provider = provider,
    }
end

---@param provider IssuesProvider
---@param repo AtlasTarget
---@param opts table
---@return IssuesViewConfig
local function issue_view_for(provider, repo, opts)
    local view
    local search = vim.trim(opts.search or '')

    if search ~= '' then
        -- Explicit searches are still scoped to the current repository.
        view = {
            name = 'Search',
            layout = 'compact',
            search = ('repo:%s %s'):format(repo.repo_full_name, search),
        }
    elseif provider.id == 'github' then
        -- Prefer Atlas' configured current-repo view when present. Reusing its
        -- exact search string means the dashboard and this picker hit the same
        -- cache entry.
        for _, candidate in ipairs(provider.views()) do
            ---@cast candidate AtlasGitHubIssuesViewConfig
            if candidate.current_repo then
                ---@type AtlasGitHubIssuesViewConfig
                local configured = vim.deepcopy(candidate)
                -- Resolve the repository ourselves instead of letting Atlas
                -- call `git` again against the process cwd.
                configured.current_repo = nil
                configured.search = vim.trim(
                    ('repo:%s %s'):format(repo.repo_full_name, configured.search or '')
                )
                view = configured
                break
            end
        end
    end

    view = view
        or {
            name = 'This repo',
            layout = 'compact',
            search = ('repo:%s is:issue is:open'):format(repo.repo_full_name),
        }

    local qualifiers = {}
    for _, name in ipairs(ISSUE_FILTER_NAMES) do
        if opts[name] then
            qualifiers[#qualifiers + 1] = ISSUE_FILTERS[name].qualifier
        end
    end
    if #qualifiers > 0 then
        view.search =
            vim.trim((view.search or '') .. ' ' .. table.concat(qualifiers, ' '))
    end

    return view
end

---@param opts table
---@param ctx snacks.picker.finder.ctx
---@return snacks.picker.finder.result
local function issue_finder(opts, ctx)
    local Snacks = require('snacks')
    local cwd = ctx:cwd()

    -- `require("atlas")` also lets laze load/configure the plugin on first use
    -- if it has not been opened through `:Atlas` yet. Do it before entering the
    -- async finder, where Neovim API calls would be disallowed.
    local ok, atlas_err = pcall(require, 'atlas')
    if not ok then
        Snacks.notify.error('atlas.nvim is unavailable: ' .. tostring(atlas_err))
        return {}
    end
    local git = require('atlas.core.git')

    ---@async
    return function(cb)
        local cancelled = false
        local current

        ctx.async:on('abort', function()
            cancelled = true
            if current and current.cancel then
                pcall(current.cancel)
            end
        end)

        ---@param start fun(done: fun(value: any, err: any)): { cancel: fun() }|nil
        ---@return any, any
        local function await(start)
            local done = false
            local value, err
            -- Atlas uses Neovim APIs (vim.fn, nvim_buf_get_name, ...) for git
            -- and cache work. Run that on the main loop instead of the async
            -- fast-event context.
            vim.schedule(function()
                if cancelled then
                    return
                end
                local started, handle = pcall(start, function(result, failure)
                    done = true
                    value, err = result, failure
                    ctx.async:resume()
                end)
                if not started then
                    done = true
                    err = tostring(handle)
                    ctx.async:resume()
                    return
                end
                if not done then
                    current = handle
                end
            end)
            if not done then
                ---@diagnostic disable-next-line: await-in-sync
                ctx.async:suspend()
            end
            current = nil
            if cancelled then
                error('aborted', 0)
            end
            return value, err
        end

        local repo, repo_err = await(function(done)
            return git.local_repository(cwd, done)
        end)
        if not repo then
            Snacks.notify.warn(
                repo_err or 'No supported Git repository found',
                { title = 'Issues' }
            )
            return
        end

        -- Loading provider modules and building the view can create namespaces
        -- and touch other Neovim APIs, so keep this on the main loop too.
        local result, setup_err = await(function(done)
            local config = require('atlas.config')
            if not config.provider_options(repo.provider) then
                done(nil, 'Atlas provider not configured: ' .. tostring(repo.provider))
                return
            end

            local providers = require('atlas.providers')
            local provider = providers.load(repo.provider, 'issues')
            if not provider then
                done(nil, 'Issues are not supported for ' .. tostring(repo.provider))
                return
            end
            ---@cast provider IssuesProvider

            if provider.id ~= 'github' then
                local enabled = false
                for _, name in ipairs(ISSUE_FILTER_NAMES) do
                    enabled = enabled or opts[name]
                end
                if enabled then
                    done(nil, 'Issue filters are only implemented for GitHub')
                    return
                end
            end

            local force_refresh = opts.atlas_force_refresh == true
            opts.atlas_force_refresh = nil

            local view = issue_view_for(provider, repo, opts)
            return provider.capabilities.core.fetch_issues(view, {
                force_refresh = force_refresh,
                pagelen = opts.pagelen or 50,
            }, function(page, errors)
                done({
                    provider = provider,
                    page = page,
                    errors = errors,
                }, nil)
            end)
        end)
        if not result then
            Snacks.notify.warn(
                setup_err or 'Unable to load Atlas issue provider',
                { title = 'Issues' }
            )
            return
        end

        local provider = result.provider
        local page = result.page
        local fetch_errors = result.errors
        local items = page and page.items or {}
        local errors = type(fetch_errors) == 'table' and fetch_errors
            or (fetch_errors and { tostring(fetch_errors) })
            or {}
        if #errors > 0 then
            local message = table.concat(errors, '; ')
            if #items == 0 then
                Snacks.notify.error(message, { title = 'Issues' })
                return
            end
            Snacks.notify.warn(message, { title = 'Issues' })
        end

        for _, issue in ipairs(items) do
            cb(issue_entry(issue, provider))
        end
    end
end

---@param issue Issue
---@param details IssueDetails|nil
---@return string[]
local function issue_preview_lines(issue, details)
    local utils = require('atlas.ui.shared.utils')
    local reporter = issue.reporter and issue.reporter.username or ''
    local lines = {
        ('# %s %s'):format(issue.key, issue.title),
        '',
        ('**State:** %s  **Reporter:** %s'):format(
            issue.status or '-',
            reporter ~= '' and ('@' .. reporter) or '-'
        ),
        ('**Updated:** %s'):format(utils.relative_time(issue.updated_at)),
    }

    if details then
        local assignees = vim.tbl_map(function(user)
            return '@' .. (user.username or user.name)
        end, details.assignees or {})
        local labels = vim.tbl_map(function(label)
            return label.name
        end, details.labels or {})

        lines[#lines + 1] = '**Assignees:** '
            .. (#assignees > 0 and table.concat(assignees, ', ') or 'Unassigned')
        if #labels > 0 then
            lines[#lines + 1] = '**Labels:** ' .. table.concat(labels, ', ')
        end
        if details.milestone then
            lines[#lines + 1] = '**Milestone:** ' .. details.milestone.title
        end

        lines[#lines + 1] = ''
        lines[#lines + 1] = '---'
        lines[#lines + 1] = ''
        lines[#lines + 1] = '## Description'
        lines[#lines + 1] = ''
        vim.list_extend(
            lines,
            vim.split((details.description or ''):gsub('\r\n', '\n'), '\n', {
                plain = true,
            })
        )
    end

    return lines
end

---@type snacks.picker.format
M.format_issue = function(item)
    local issue = item.item
    local icon, icon_hl = issue_state_icon(issue.status_id)
    local utils = require('atlas.ui.shared.utils')
    local Snacks = require('snacks')
    local align = Snacks.picker.util.align
    local truncate = Snacks.picker.util.truncate
    local title = issue.title

    local ret = {
        { icon .. ' ', icon_hl },
        { '#' .. tostring(issue.number or issue.key) .. ' ', 'SnacksPickerDimmed' },
        {
            '',
            resolve = function(max_width)
                return { { flex_title(truncate, title, max_width) } }
            end,
        },
        {
            '',
            resolve = function(max_width)
                return { { (' '):rep(max_width) } }
            end,
        },
    }

    if issue.reporter and issue.reporter.username ~= '' then
        ret[#ret + 1] = { ' @' .. issue.reporter.username, 'SnacksPickerGitAuthor' }
    end
    ret[#ret + 1] = {
        ' ' .. align(utils.relative_time(issue.updated_at), 3, { align = 'right' }),
        'SnacksPickerGitDate',
    }
    -- Reserve two columns at the right edge (the list already adds a leading
    -- margin). Snacks strips this trailing whitespace after resolving the
    -- flexible spacer.
    ret[#ret + 1] = { '  ' }
    return ret
end

---@type snacks.picker.preview
M.preview_issue = function(ctx)
    local issue = ctx.item.item
    local provider = ctx.item.provider
    ctx.preview:reset()
    ctx.preview:set_title(('%s %s'):format(issue.key, issue.title))
    ctx.preview:set_lines(issue_preview_lines(issue))
    ctx.preview:highlight({ ft = 'markdown' })

    if not provider then
        return
    end

    provider.capabilities.core.fetch_issue(issue, nil, function(details, err)
        vim.schedule(function()
            if
                ctx.picker.closed
                or ctx.preview.item ~= ctx.item
                or not ctx.preview.win:valid()
            then
                return
            end
            if not details then
                ctx.preview:notify(
                    tostring(err or 'Failed to load issue'),
                    'error',
                    { item = false }
                )
                return
            end
            ctx.preview:set_lines(issue_preview_lines(issue, details))
            ctx.preview:highlight({ ft = 'markdown' })
        end)
    end)
end

---@param picker snacks.Picker
---@param item snacks.picker.finder.Item|nil
local function open_issue_detail(picker, item)
    if not item then
        return
    end
    local issue = item.item
    local provider = item.provider
    picker:close()
    vim.schedule(function()
        require('atlas.issues.ui.detail').open(issue, { provider = provider })
    end)
end

---@param picker snacks.Picker
---@param item snacks.picker.finder.Item|nil
local function develop_issue(picker, item)
    if not item then
        return
    end
    local issue = item.item
    local Snacks = require('snacks')
    if issue.status_id ~= 'open' then
        Snacks.notify.warn('Only open issues can be developed', {
            title = 'Issues',
        })
        return
    end

    local gh_actions = require('snacks.gh.actions')
    ---@type any
    local legacy = {
        type = 'issue',
        number = issue.number,
        repo = issue.repo_full_name,
        state = issue.status_id,
        uri = issue.url or issue.key,
    }
    -- Atlas has no branch action for issues; keep the previous snacks/gh
    -- `gh issue develop --checkout` behavior.
    gh_actions.run(legacy, {
        cmd = 'develop',
        icon = icons.git.branch,
        type = 'issue',
        args = { '--checkout' },
        title = 'Create branch for issue #{number}',
        success = 'Created and checked out branch for issue #{number}',
    }, { picker = picker, items = { legacy } })
end

---@param picker snacks.Picker
---@param item snacks.picker.finder.Item|nil
local function open_issue_actions(picker, item)
    if not item then
        return
    end
    local Snacks = require('snacks')
    local context = { provider = item.provider, issue = item.item }
    require('atlas.issues.actions').open(context, function(result, err)
        if err then
            Snacks.notify.error(tostring(err), { title = 'Issues' })
        elseif result then
            vim.schedule(function()
                if not picker.closed then
                    local opts = picker.opts --[[@as table]]
                    opts.atlas_force_refresh = true
                    picker:find({ refresh = true })
                end
            end)
        end
    end, {
        {
            label = 'Create branch',
            icon = icons.git.branch,
            callback = function()
                develop_issue(picker, item)
            end,
        },
    })
end

local issue_toggles, issue_actions = {}, {}
local issue_input_keys, issue_list_keys = {}, {}

for _, name in ipairs(ISSUE_FILTER_NAMES) do
    local filter = ISSUE_FILTERS[name]
    issue_toggles[name] = { icon = filter.icon }
    issue_input_keys[filter.key] = {
        'atlas_issue_toggle_' .. name,
        mode = { 'n', 'i' },
        desc = filter.desc,
    }
    issue_list_keys[filter.key] = {
        'atlas_issue_toggle_' .. name,
        desc = filter.desc,
    }
    issue_actions['atlas_issue_toggle_' .. name] = function(picker)
        local enable = not picker.opts[name]
        for _, other in ipairs(ISSUE_FILTER_NAMES) do
            picker.opts[other] = (other == name and enable) or nil
        end
        picker.list:set_target()
        picker:find()
    end
end

issue_actions.atlas_issue_refresh = function(picker)
    picker.opts.atlas_force_refresh = true
    picker:find({ refresh = true })
end

issue_actions.atlas_issue_develop = develop_issue
issue_actions.atlas_issue_actions = open_issue_actions

issue_input_keys['<A-s>'] = {
    'atlas_issue_actions',
    mode = { 'n', 'i' },
    desc = 'Issue actions',
}
issue_list_keys['<A-s>'] = {
    'atlas_issue_actions',
    desc = 'Issue actions',
}
issue_input_keys['<C-o>'] = {
    'atlas_issue_develop',
    mode = { 'n', 'i' },
    desc = 'Create branch for issue',
}
issue_list_keys['<C-o>'] = {
    'atlas_issue_develop',
    desc = 'Create branch for issue',
}
issue_input_keys['<C-r>'] = {
    'atlas_issue_refresh',
    mode = { 'n', 'i' },
    desc = 'Refresh from GitHub',
}
issue_list_keys['<C-r>'] = {
    'atlas_issue_refresh',
    desc = 'Refresh from GitHub',
}

disable_source_keys(issue_input_keys)
disable_source_keys(issue_list_keys)

---@type snacks.picker.Config
M.issue = {
    title = icons.git.github .. '  Issues',
    finder = issue_finder,
    format = M.format_issue,
    preview = M.preview_issue,
    confirm = open_issue_detail,
    sort = { fields = { 'score:desc', 'idx' } },
    toggles = issue_toggles,
    actions = issue_actions,
    -- Typing filters the list locally; only toggles/refresh refetch.
    live = false,
    supports_live = false,
    show_delay = 0,
    win = {
        input = { keys = issue_input_keys },
        list = { keys = issue_list_keys },
        preview = {
            wo = {
                conceallevel = 3,
                concealcursor = 'nvic',
            },
        },
    },
}

return M
