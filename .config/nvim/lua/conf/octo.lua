local M = {}

local n = require 'nui-components'

local renderer = n.create_renderer {
    width = 60,
    height = 20,
}

renderer:on_mount(function()
    local augroup = vim.api.nvim_create_augroup('OcroPrForm', { clear = true })
    vim.api.nvim_create_autocmd('WinLeave', {
        group = augroup,
        callback = function()
            vim.schedule(function()
                if renderer.layout and renderer.layout._.mounted then
                    local wins = vim.tbl_map(
                        function(c) return c.winid end,
                        renderer:get_focusable_components()
                    )
                    if not vim.tbl_contains(wins, vim.api.nvim_get_current_win()) then
                        vim.api.nvim_del_augroup_by_name 'OcroPrForm'
                        renderer:close()
                    end
                end
            end)
        end,
    })
end)

local signal = n.create_signal {
    is_loading = false,
    labels = {},
}

local function reset_signal()
    signal.is_loading = false
    signal.labels = {}
end

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
            submit_key = '<S-CR>',
            on_submit = function(is_valid)
                require('coop').spawn(function()
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
                        require('gh').pr.refresh()
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
            size = 7,
            autoresize = true,
            on_change = function(_, component)
                vim.schedule(function()
                    local visual_lines = vim.api.nvim_win_text_height(component.winid, {}).all
                    local new_size = math.max(7, visual_lines)
                    component._private.text_input_signal.size = new_size
                    renderer:set_size { height = 13 + new_size }
                end)
            end,
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
                ---@diagnostic disable-next-line: undefined-field
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

M.pr = {}

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

---@async
---@return string?
M.pr.form_create = function()
    local title = require('git').async.last_commit_title()
    local labels = require('gh').labels()

    renderer:render(function()
        return create_pr_form { title = title, labels = labels }
    end)
end

---@async
---@param opts gh.pr.create.Opts
---@return string?
M.pr.create = function(opts)
    ---@type gh.pr.create.Opts
    opts = vim.tbl_extend('keep', opts, {
        -- assignee = '@me',
        draft = true,
    })
    local git = require('git').async

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

    local stdout, stderr = require('gh').pr.create(opts)
    reset_signal()

    if stderr and stderr ~= '' and not stderr:match '^Warning: ' then
        Snacks.notify.error(stderr)
    end

    if stdout and stdout ~= '' then
        return stdout
    end
end

return M
