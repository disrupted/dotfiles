local M = {}

local n = require 'nui-components'

local renderer = n.create_renderer {
    width = 60,
    height = 30,
}

local signal = n.create_signal {
    is_loading = false,
}

---@class gitlab.mr.create.form.Opts
---@field title? string

---@param opts gitlab.mr.create.form.Opts
local create_mr_form = function(opts)
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

                    local out = M.mr.create {
                        title = title,
                        body = body,
                    }
                    if out then
                        renderer:close()
                        Snacks.notify(
                            { 'MR created', out },
                            { title = 'GitLab' }
                        )
                        require('coop.uv-utils').sleep(500)
                        require('glab').mr.refresh()
                        M.mr.open()
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
        n.columns(
            n.button {
                label = 'Create MR',
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

M.mr = {}

---@param opts? gitlab.mr.open.Opts
M.mr.open = function(opts)
    ---@class gitlab.mr.open.Opts
    ---@field browser boolean
    opts = vim.tbl_extend('keep', opts or {}, {
        browser = true,
    })
    if opts.browser then
        vim.system { 'glab', 'mr', 'view', '--web' }
    end
end

---@async
---@return string?
M.mr.form_create = function()
    local title = require('git').async.last_commit_title()

    renderer:render(function()
        return create_mr_form { title = title }
    end)
end

---@async
---@param opts glab.mr.create.Opts
---@return string?
M.mr.create = function(opts)
    ---@type glab.mr.create.Opts
    opts = vim.tbl_extend('keep', opts, {
        assignee = vim.env.GITLAB_USERNAME,
    })
    local git = require('git').async

    if not opts.target then
        -- if upstream tracking branch was changed we want to
        -- create the MR against that branch instead of main
        local tracking_branch = git.tracking_branch()
        if tracking_branch then
            tracking_branch = tracking_branch:gsub('^origin/', '')
            if git.current_branch() ~= tracking_branch then
                opts.target = tracking_branch
            end
        end
    end

    local stdout, stderr = require('glab').mr.create(opts)
    signal.is_loading = false
    if stderr and stderr ~= '' then
        Snacks.notify.error(stderr)
        return
    end
    return stdout
end

return M
