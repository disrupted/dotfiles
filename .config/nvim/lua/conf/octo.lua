local coop = require 'coop'
local git = require('git').async

local M = {}

M.pr = {}

local gh = {
    ---@async
    ---@param opts table
    ---@return string? out
    run = function(opts)
        local cmd = opts.args
        table.insert(cmd, 1, 'gh')
        local out = require('coop.vim').system(cmd)
        -- assert(out.code == 0)
        return out.stdout
    end,
    -- TODO: decide whether we want to keep it
    ---@async
    ---@param opts table
    ---@return string? out
    octo_run = function(opts)
        return coop.cb_to_tf(function(cb)
            opts.cb = cb
            require('octo.gh').run(opts)
        end)()
    end,
    pr = {
        ---@async
        ---@param opts octo.pr.create.Opts
        ---@return string? stdout
        ---@return string? stderr
        create = function(opts)
            ---@type string[]
            local cmd = { 'gh', 'pr', 'create' }
            table.insert(cmd, '--title')
            table.insert(cmd, opts.title)
            table.insert(cmd, '--body')
            table.insert(cmd, opts.body)
            if opts.assignee and opts.assignee ~= '' then
                table.insert(cmd, '--assignee')
                table.insert(cmd, opts.assignee)
            end
            if opts.draft then
                table.insert(cmd, '--draft')
            end
            for _, label in ipairs(opts.label) do
                table.insert(cmd, '--label')
                table.insert(cmd, label)
            end
            if opts.base and opts.base ~= '' then
                table.insert(cmd, '--base')
                table.insert(cmd, opts.base)
            end

            local out = require('coop.vim').system(cmd)
            -- assert(out.code == 0)
            return out.stdout, out.stderr
        end,
        -- TODO: decide whether we want to keep it
        ---@async
        ---@param opts table
        ---@return string? out
        ---@return string? stderr
        octo_create = function(opts)
            return coop.cb_to_tf(function(cb)
                opts = vim.tbl_deep_extend('keep', opts, { opts = { cb = cb } })
                require('octo.gh').pr.create(opts)
            end)()
        end,
    },
}

---@async
---@param args string[]
---@param json_fields string[]
---@return table
M.json = function(args, json_fields)
    assert(
        not json_fields or (json_fields and not vim.tbl_isempty(json_fields)),
        'Specify one or more JSON fields to query'
    )
    table.insert(args, '--json')
    table.insert(args, table.concat(json_fields, ','))
    local out = gh.run { args = args }
    if out and out ~= '' then
        return vim.json.decode(out)
    end
    return {}
end

---@class Label
---@field name string

---@async
---@return Label[]
M.labels = function()
    return M.json({ 'label', 'list' }, { 'name' })
end

---@async
---@param json_fields string[]
---@return table<string, any>
M.pr.json = function(json_fields)
    return M.json({ 'pr', 'view' }, json_fields)
end

---@async
---@param json_field string
---@return string?
M.pr.meta = function(json_field)
    local out = gh.run {
        args = {
            'pr',
            'view',
            '--json',
            json_field,
            '-q',
            '.' .. json_field,
        },
    }
    if out and out ~= '' then
        return out
    end
end

---@async
---@return boolean
M.pr.exists = function()
    return M.pr.meta 'number' and true or false
end

---@param opts? octo.pr.open.Opts
M.pr.open = function(opts)
    ---@class octo.pr.open.Opts
    ---@field octo boolean
    ---@field browser boolean
    opts = vim.tbl_extend('keep', opts or {}, {
        octo = true,
        browser = false,
    })
    if opts.octo then
        Snacks.notify('Opening PR...', { title = 'Octo' })
        vim.cmd.tabnew()
        vim.cmd 'Octo pr'
    end
    if opts.browser then
        vim.cmd 'Octo pr browser'
    end
end

local n = require 'nui-components'

local renderer = n.create_renderer {
    width = 60,
    height = 30,
}

local signal = n.create_signal {
    is_loading = false,
    labels = {},
}

---@class octo.pr.create.form.Opts
---@field title? string
---@field labels? Label[]

---@param opts octo.pr.create.form.Opts
local create_pr_form = function(opts)
    local labels_data = {}
    for _, label in ipairs(opts.labels) do
        table.insert(labels_data, n.option(label.name, { id = label.name }))
    end

    return n.form(
        {
            id = 'form',
            submit_key = '<S-CR>', -- FIXME: does not work inside tmux
            on_submit = function(is_valid)
                coop.spawn(function()
                    if not is_valid then
                        Snacks.notify.error 'Title is required'
                        return
                    end
                    signal.is_loading = true

                    local title = vim.trim(
                        renderer:get_component_by_id('title'):get_current_value()
                    )
                    local body = vim.trim(
                        renderer:get_component_by_id('body'):get_current_value()
                    )

                    local out = M.pr.create {
                        title = title,
                        body = body,
                        label = vim.iter(signal.labels:get_value())
                            :map(function(label)
                                return label.id
                            end)
                            :totable(),
                    }
                    if out then
                        renderer:close()
                        Snacks.notify({ 'PR created', out }, { title = 'Octo' })
                        require('coop.uv-utils').sleep(500)
                        M.pr.refresh()
                        M.pr.open()
                    end
                end)
            end,
        },
        n.text_input {
            id = 'title',
            border_label = ' Title ',
            filetype = 'gitcommit',
            value = opts.title,
            autofocus = true,
            size = 1,
            max_lines = 1,
            validate = n.validator.min_length(3),
        },
        n.text_input {
            id = 'body',
            border_label = ' Body ',
            filetype = 'markdown',
            flex = 1,
        },
        n.select {
            border_label = ' Labels ',
            size = 5,
            selected = signal.labels,
            data = labels_data,
            multiselect = true,
            on_select = function(nodes)
                signal.labels = nodes
            end,
        },
        n.columns(
            n.button {
                label = 'Create PR',
                on_press = function()
                    ---@diagnostic disable-next-line: undefined-field
                    if signal.is_loading:get_value() then
                        return -- prevent duplicate submit
                    end
                    local form = renderer:get_component_by_id 'form'
                    assert(form)
                    form:submit()
                end,
                is_active = signal.is_loading:get_value(),
            },
            n.spinner {
                is_loading = signal.is_loading,
                padding = { left = 1 },
                ---@diagnostic disable-next-line: undefined-field
                hidden = signal.is_loading:negate(),
            },
            n.gap { flex = 1 },
            n.paragraph {
                lines = '<S-CR> Submit',
                align = 'right',
                is_focusable = false,
            },
            n.gap(1),
            n.paragraph {
                lines = '<Esc> Cancel',
                align = 'right',
                is_focusable = false,
            }
        )
    )
end

---@async
---@return string?
M.pr.form_create = function()
    local title = git.last_commit_title()
    local labels = M.labels()

    renderer:render(function()
        return create_pr_form { title = title, labels = labels }
    end)
end

---@class octo.pr.create.Opts
---@field title string
---@field body string
---@field assignee? string
---@field draft? boolean
---@field label string[]
---@field base? string

---@async
---@param opts octo.pr.create.Opts
---@return string?
M.pr.create = function(opts)
    ---@type octo.pr.create.Opts
    opts = vim.tbl_extend('keep', opts, {
        assignee = '@me',
        draft = true,
    })

    if opts.base == nil then
        -- if upstream tracking branch was changed we want to
        -- create the PR against that branch instead of main
        local tracking_branch = git.tracking_branch()
        if tracking_branch then
            tracking_branch = tracking_branch:gsub('^origin/', '')
            if git.current_branch() ~= tracking_branch then
                opts.base = tracking_branch
            end
        end
    end

    local stdout, stderr = gh.pr.create(opts)
    signal.is_loading = false
    if stderr and stderr ~= '' then
        Snacks.notify.error(stderr)
        if
            not stderr:match 'Warning: ' -- e.g. 'Warning: 2 uncommitted changes'
        then
            -- abort if not just a warning
            return
        end
    end
    return stdout
end

---@async
M.pr.refresh = function()
    vim.g.git_pr = M.pr.json { 'state', 'title' }
end

return M
