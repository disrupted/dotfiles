local M = {}

local system = require('conf.async').system
local icons = require('conf.icons')

---@type any, any, any
local n, renderer, signal

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
        local augroup = vim.api.nvim_create_augroup('GitHubPrForm', { clear = true })
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
                            vim.api.nvim_del_augroup_by_name('GitHubPrForm')
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

---@param stderr string?
---@return string?
local function extract_gh_error(stderr)
    if stderr == nil or stderr == '' then
        return nil
    end

    local lines = {}
    for line in stderr:gmatch('[^\r\n]+') do
        local trimmed = vim.trim(line)
        if trimmed ~= '' and not trimmed:match('^Warning: ') then
            table.insert(lines, trimmed)
        end
    end

    if #lines == 0 then
        return nil
    end

    return table.concat(lines, '\n')
end

---@class github.pr.create.form.Opts
---@field title? string
---@field labels? Label[]

---@param opts github.pr.create.form.Opts
local create_pr_form = function(opts)
    local labels_data = {}
    if opts.labels then
        for _, label in ipairs(opts.labels) do
            table.insert(labels_data, n.option(label.name, { id = label.name }))
        end
    end

    return n.form(
        {
            id = 'form',
            submit_key = '<S-CR>',
            on_submit = function(is_valid)
                local task = vim.async.run(function()
                    if not is_valid then
                        Snacks.notify.error('Title is required')
                        return
                    end

                    signal.is_loading = true

                    local title = vim.trim(
                        renderer:get_component_by_id('title'):get_current_value()
                    )
                    local body = vim.trim(
                        renderer:get_component_by_id('body'):get_current_value()
                    )

                    local out, err = M.pr.create({
                        title = title,
                        body = body,
                        label = vim.iter(signal.labels:get_value())
                            :map(function(label)
                                return label.id
                            end)
                            :totable(),
                    })
                    if out then
                        renderer:close()
                        Snacks.notify({ 'PR created', out }, { title = 'GitHub' })
                        vim.async.sleep(500)
                        require('gh').pr.refresh()
                        M.pr.open()
                    elseif err == nil then
                        Snacks.notify.error(
                            'Failed to create PR. Run :messages for details.'
                        )
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
                label = 'Create PR',
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

M.pr = {}

---@class github.pr.open.Opts
---@field number? integer

---@async
---@param opts? github.pr.open.Opts
M.pr.open = function(opts)
    opts = opts or {}
    local number = opts.number
    if not number then
        local pr = require('gh').pr.json({ 'number' })
        number = pr and pr.number
    end
    if not number then
        Snacks.notify.error('Could not determine PR number', { title = 'GitHub' })
        return
    end
    Snacks.notify(('Opening PR #%d in browser...'):format(number), {
        title = 'GitHub',
    })
    local out = system({ 'gh', 'pr', 'view', tostring(number), '--web' })
    if out.code ~= 0 then
        Snacks.notify.error(out.stderr or 'Failed to open PR', { title = 'GitHub' })
    end
end

---@async
---@return string?
M.pr.form_create = function()
    local title = require('git').async.last_commit_title()
    local labels = require('gh').labels()

    ensure_ui()
    renderer:render(function()
        return create_pr_form({ title = title, labels = labels })
    end)
end

---@async
---@param opts gh.pr.create.Opts
---@return string?, string?
M.pr.create = function(opts)
    ---@type gh.pr.create.Opts
    opts = vim.tbl_extend('keep', opts, {
        -- assignee = '@me',
        draft = true,
    })
    local git = require('git')

    if opts.base == nil then
        -- if upstream tracking branch was changed we want to
        -- create the PR against that branch instead of main
        local tracking_branch = git.async.tracking_branch()
        if tracking_branch then
            local _, branch = git.split_remote_branch(tracking_branch)
            tracking_branch = branch or tracking_branch
            if git.async.current_branch() ~= tracking_branch then
                opts.base = tracking_branch
            end
        end
    end

    local stdout, stderr = require('gh').pr.create(opts)
    reset_signal()

    local err = extract_gh_error(stderr)
    if err then
        Snacks.notify.error(err)
    end

    if stdout and stdout ~= '' then
        return stdout, err
    end

    return nil, err
end

---@async
local function create_or_open_pr()
    local git = require('git').async
    local remote_url = git.remote_url()
    if require('git').match_remote_type(remote_url) ~= 'github' then
        Snacks.notify.error('Not a GitHub remote', { title = 'GitHub' })
        return
    end
    local branch = git.current_branch()
    if branch == '' then
        Snacks.notify.error('Current ref is not a valid branch', { title = 'GitHub' })
        return
    end
    if branch == git.default_branch() then
        Snacks.notify.error(
            'PR is not possible on default branch',
            { title = 'GitHub' }
        )
        return
    end
    local unpushed = git.unpushed_commits()
    if unpushed == nil then
        Snacks.notify.warn(
            'Branch has no upstream, push it with -u first',
            { title = 'GitHub' }
        )
    elseif unpushed > 0 then
        Snacks.notify.warn(
            ('%d unpushed commit(s)'):format(unpushed),
            { title = 'GitHub' }
        )
    end
    local existing_pr = require('gh').pr.json({ 'number' })
    if existing_pr then
        M.pr.open({ number = existing_pr.number })
        return
    end
    local unpushed_after = git.unpushed_commits()
    if unpushed_after == nil then
        Snacks.notify.error(
            'Branch has no upstream, push it with -u first',
            { title = 'GitHub' }
        )
        return
    elseif unpushed_after > 0 then
        Snacks.notify.warn(
            ('%d unpushed commit(s)'):format(unpushed_after),
            { title = 'GitHub' }
        )
    end
    M.pr.form_create()
end

function M.setup()
    vim.keymap.set('n', '<Leader>gop', function()
        local task = vim.async.run(create_or_open_pr)
        task:raise_on_error()
    end, {
        desc = 'View or create PR',
    })

    require('which-key').add({
        { '<Leader>go', group = 'GitHub', icon = icons.git.github },
        { '<Leader>gop', icon = icons.git.pull_request },
    })
end

return M
