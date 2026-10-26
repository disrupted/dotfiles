local M = {}

local system = require('conf.async').system
local icons = require('conf.icons')

---@type any, any, any
local n, renderer, signal

---@class forge.CreateOpts
---@field title string
---@field body string
---@field labels string[]
---@field base? string

---@class forge.Request
---@field id? integer
---@field state? string
---@field title? string

---@class forge.CreateResult
---@field code integer
---@field stdout string?
---@field stderr string?

---@class forge.Provider
---@field id 'github'|'gitlab'
---@field noun 'PR'|'MR'
---@field name 'GitHub'|'GitLab'
---@field bin string
---@field sub string
---@field draft boolean
---@field assignee? string
---@field noise string[]
---@field labels fun(): { name: string }[]
---@field view fun(): forge.Request?
---@field create fun(opts: forge.CreateOpts): forge.CreateResult
---@field refresh fun()

---@type table<string, forge.Provider>
local providers = {}

---@async
---@return { name: string }[]
local function github_labels()
    return require('gh').labels()
end

---@async
---@return forge.Request?
local function github_view()
    local pr = require('gh').pr.json({ 'number', 'state', 'title' })
    if not pr then
        return
    end
    return { id = pr.number, state = pr.state, title = pr.title }
end

---@async
---@param opts forge.CreateOpts
---@return forge.CreateResult
local function github_create(opts)
    local stdout, stderr, code = require('gh').pr.create({
        title = opts.title,
        body = opts.body,
        assignee = providers.github.assignee,
        draft = providers.github.draft,
        label = opts.labels,
        base = opts.base,
    })
    return { code = code, stdout = stdout, stderr = stderr }
end

---@async
local function github_refresh()
    require('gh').pr.refresh()
end

---@async
---@return { name: string }[]
local function gitlab_labels()
    return require('glab').labels()
end

---@async
---@return forge.Request?
local function gitlab_view()
    local mr = require('glab').mr.json()
    if not mr then
        return
    end
    return { id = mr.iid, state = mr.state, title = mr.title }
end

---@async
---@param opts forge.CreateOpts
---@return forge.CreateResult
local function gitlab_create(opts)
    local stdout, stderr, code = require('glab').mr.create({
        title = opts.title,
        body = opts.body,
        assignee = vim.env.GITLAB_USERNAME,
        draft = providers.gitlab.draft,
        label = opts.labels,
        target = opts.base,
    })
    return { code = code, stdout = stdout, stderr = stderr }
end

---@async
local function gitlab_refresh()
    require('glab').mr.refresh()
end

providers.github = {
    id = 'github',
    noun = 'PR',
    name = 'GitHub',
    bin = 'gh',
    sub = 'pr',
    draft = true,
    assignee = '@me',
    noise = { '^Warning: ' },
    labels = github_labels,
    view = github_view,
    create = github_create,
    refresh = github_refresh,
}

providers.gitlab = {
    id = 'gitlab',
    noun = 'MR',
    name = 'GitLab',
    bin = 'glab',
    sub = 'mr',
    draft = false,
    noise = { '^Creating merge request ', '^Creating draft merge request ' },
    labels = gitlab_labels,
    view = gitlab_view,
    create = gitlab_create,
    refresh = gitlab_refresh,
}

---@param remote_url string?
---@return forge.Provider?
function M.detect(remote_url)
    local override = vim.g.forge_provider
    if override then
        return providers[override]
    end

    local kind = require('git').match_remote_type(remote_url)
    return kind and providers[kind] or nil
end

local function ensure_ui()
    if n then
        return
    end

    n = require('nui-components')
    renderer = n.create_renderer({
        width = 60,
        height = 20,
        keymap = {
            close = '<Esc>',
            focus_next = '<C-n>',
            focus_prev = '<C-p>',
        },
    })

    renderer:on_mount(function()
        local augroup =
            vim.api.nvim_create_augroup('ForgeRequestForm', { clear = true })
        vim.api.nvim_create_autocmd('WinLeave', {
            group = augroup,
            callback = function()
                vim.schedule(function()
                    if renderer.layout and renderer.layout._.mounted then
                        local wins = vim.tbl_map(function(c)
                            return c.winid
                        end, renderer:get_focusable_components())
                        if
                            not vim.tbl_contains(wins, vim.api.nvim_get_current_win())
                        then
                            vim.api.nvim_del_augroup_by_name('ForgeRequestForm')
                            renderer:close()
                        end
                    end
                end)
            end,
        })
    end)

    signal = n.create_signal({
        is_loading = false,
        labels = {},
    })
end

local function reset_signal()
    signal.is_loading = false
    signal.labels = {}
end

---@param provider forge.Provider
---@param stderr string?
---@return string?
local function stderr_message(provider, stderr)
    if stderr == nil or stderr == '' then
        return nil
    end

    local lines = {}
    for line in stderr:gmatch('[^\r\n]+') do
        local trimmed = vim.trim(line)
        if trimmed ~= '' then
            local noise = false
            for _, pattern in ipairs(provider.noise) do
                if trimmed:match(pattern) then
                    noise = true
                    break
                end
            end
            if not noise then
                table.insert(lines, trimmed)
            end
        end
    end

    if #lines == 0 then
        return nil
    end

    return table.concat(lines, '\n')
end

---@class forge.form.Opts
---@field title? string
---@field labels? { name: string }[]

---@param provider forge.Provider
---@param opts forge.form.Opts
local function create_form(provider, opts)
    local labels_data = {}
    for _, label in ipairs(opts.labels or {}) do
        table.insert(labels_data, n.option(label.name, { id = label.name }))
    end

    return n.form(
        {
            id = 'form',
            submit_key = '<S-CR>',
            on_submit = function(is_valid)
                local task = vim.async.run(function()
                    if not is_valid then
                        Snacks.notify.error('Title is required', {
                            title = provider.name,
                        })
                        return
                    end

                    signal.is_loading = true

                    local title = vim.trim(
                        renderer:get_component_by_id('title'):get_current_value()
                    )
                    local body = vim.trim(
                        renderer:get_component_by_id('body'):get_current_value()
                    )

                    local out = M.create(provider, {
                        title = title,
                        body = body,
                        labels = vim.iter(signal.labels:get_value())
                            :map(function(label)
                                return label.id
                            end)
                            :totable(),
                    })
                    if out ~= nil then
                        renderer:close()
                        local message = { provider.noun .. ' created' }
                        if out ~= '' then
                            table.insert(message, out)
                        end
                        Snacks.notify(message, { title = provider.name })
                        vim.async.sleep(500)
                        provider.refresh()
                        M.open(provider)
                    end
                end)
                task:raise_on_error()
            end,
        },
        n.text_input({
            id = 'title',
            border_label = ' Title ',
            filetype = 'gitcommit',
            value = opts.title,
            autofocus = true,
            size = 1,
            max_lines = 1,
            validate = n.validator.min_length(3),
        }),
        n.text_input({
            id = 'body',
            border_label = ' Body ',
            filetype = 'markdown',
            size = 7,
            autoresize = true,
            on_change = function(_, component)
                vim.schedule(function()
                    local visual_lines =
                        vim.api.nvim_win_text_height(component.winid, {}).all
                    local new_size = math.max(7, visual_lines)
                    component._private.text_input_signal.size = new_size
                    renderer:set_size({ height = 13 + new_size })
                end)
            end,
        }),
        n.select({
            border_label = ' Labels ',
            size = 5,
            selected = signal.labels,
            data = labels_data,
            multiselect = true,
            on_select = function(nodes)
                signal.labels = nodes
            end,
        }),
        n.columns(
            n.button({
                label = 'Create ' .. provider.noun,
                on_press = function()
                    ---@diagnostic disable-next-line: undefined-field
                    if signal.is_loading:get_value() then
                        return -- prevent duplicate submit
                    end
                    local form = renderer:get_component_by_id('form')
                    assert(form)
                    form:submit()
                end,
                ---@diagnostic disable-next-line: undefined-field
                is_active = signal.is_loading:get_value(),
            }),
            n.spinner({
                is_loading = signal.is_loading,
                padding = { left = 1 },
                ---@diagnostic disable-next-line: undefined-field
                hidden = signal.is_loading:negate(),
            }),
            n.gap({ flex = 1 }),
            n.paragraph({
                lines = '<S-CR> Submit',
                align = 'right',
                is_focusable = false,
            }),
            n.gap(1),
            n.paragraph({
                lines = '<Esc> Cancel',
                align = 'right',
                is_focusable = false,
            })
        )
    )
end

---@async
---@param provider forge.Provider
---@param id? integer
function M.open(provider, id)
    local number = id or (provider.view() or {}).id
    if not number then
        Snacks.notify.error(
            ('Could not determine %s number'):format(provider.noun),
            { title = provider.name }
        )
        return
    end

    Snacks.notify(
        ('Opening %s #%d in browser...'):format(provider.noun, number),
        { title = provider.name }
    )
    local out = system({
        provider.bin,
        provider.sub,
        'view',
        tostring(number),
        '--web',
    })
    if out.code ~= 0 then
        Snacks.notify.error(
            out.stderr or ('Failed to open ' .. provider.noun),
            { title = provider.name }
        )
    end
end

---@async
---@param provider forge.Provider
---@return string?
function M.create(provider, opts)
    if opts.base == nil then
        -- if upstream tracking branch was changed we want to
        -- create the request against that branch instead of main
        local git = require('git')
        local tracking_branch = git.async.tracking_branch()
        if tracking_branch then
            local _, branch = git.split_remote_branch(tracking_branch)
            branch = branch or tracking_branch
            if git.async.current_branch() ~= branch then
                opts.base = branch
            end
        end
    end

    local out = provider.create(opts)
    reset_signal()

    if out.code ~= 0 then
        Snacks.notify.error(
            stderr_message(provider, out.stderr)
                or ('Failed to create ' .. provider.noun),
            { title = provider.name }
        )
        return nil
    end

    return vim.trim(out.stdout or '')
end

---@async
---@param provider forge.Provider
function M.form_create(provider)
    local title = require('git').async.last_commit_title()
    local labels = provider.labels()

    ensure_ui()
    reset_signal()
    renderer:set_size({ height = 20 })
    renderer:render(function()
        return create_form(provider, { title = title, labels = labels })
    end)
end

---@async
---@param provider forge.Provider
local function create_or_open(provider)
    local git = require('git').async
    local branch = git.current_branch()
    if not branch or branch == '' then
        Snacks.notify.error('Current ref is not a valid branch', {
            title = provider.name,
        })
        return
    end

    local default_branch = git.default_branch()
    if default_branch and branch == default_branch then
        Snacks.notify.error(
            ('%s is not possible on default branch'):format(provider.noun),
            { title = provider.name }
        )
        return
    end

    local existing = provider.view()
    if existing and existing.id then
        M.open(provider, existing.id)
        return
    end

    local unpushed = git.unpushed_commits()
    if unpushed == nil then
        Snacks.notify.error('Branch has no upstream, push it with -u first', {
            title = provider.name,
        })
        return
    elseif unpushed > 0 then
        Snacks.notify.warn(('%d unpushed commit(s)'):format(unpushed), {
            title = provider.name,
        })
    end

    M.form_create(provider)
end

---@async
local function create_or_open_current()
    local remote_url = require('git').async.remote_url()
    local provider = M.detect(remote_url)
    if not provider then
        Snacks.notify.error('Unsupported Git remote (GitHub or GitLab)', {
            title = 'Forge',
        })
        return
    end

    create_or_open(provider)
end

function M.setup()
    require('which-key').add({
        {
            '<Leader>gP',
            function()
                local task = vim.async.run(create_or_open_current)
                task:raise_on_error()
            end,
            icon = icons.git.pull_request,
            desc = 'View or create PR',
        },
    })
end

return M
