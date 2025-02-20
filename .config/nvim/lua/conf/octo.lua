local M = {}

M.pr = {}

local gh = {
    ---@async
    ---@param opts table
    ---@return string? out
    run = function(opts)
        local cb_to_co = require('coop.coroutine-utils').cb_to_co
        ---@param cb fun(out: string?)
        return cb_to_co(function(cb)
            opts.cb = cb
            require('octo.gh').run(opts)
        end)()
    end,
    pr = {
        ---@async
        ---@param opts table
        ---@return string? out
        ---@return string? stderr
        create = function(opts)
            local cb_to_co = require('coop.coroutine-utils').cb_to_co
            ---@param cb fun(out: string?)
            return cb_to_co(function(cb)
                opts = vim.tbl_deep_extend('keep', opts, { opts = { cb = cb } })
                require('octo.gh').pr.create(opts)
            end)()
        end,
    },
}

-- TODO: upstream into coop.nvim
local coop = {
    ui = {
        ---@async
        ---@param opts? snacks.input.Opts
        ---@return string? user input value
        input = function(opts)
            local cb_to_tf = require('coop.task-utils').cb_to_tf
            local shift_parameters =
                require('coop.functional-utils').shift_parameters
            return cb_to_tf(shift_parameters(vim.ui.input))(opts)
        end,
    },
}

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
        Snacks.notify 'Opening PR...'
        vim.cmd 'Octo pr'
    end
    if opts.browser then
        vim.cmd 'Octo pr browser'
    end
end

---@async
---@param opts? octo.pr.open.Opts
M.pr.create = function(opts)
    -- FIXME: doesn't open input afterwards if this is enabled
    -- local last_commit_title = require('conf.git').last_commit_title()

    local title = coop.ui.input {
        prompt = 'PR title',
        -- default = last_commit_title,
        win = { ft = 'gitcommit' },
    }
    if not title or title == '' then
        return
    end

    local body = coop.ui.input {
        prompt = 'PR body',
        win = { ft = 'markdown' },
    }
    if not body then
        return
    end

    local _, stderr = gh.pr.create {
        title = title,
        body = body,
        assignee = 'disrupted',
        draft = true,
    }
    if stderr and stderr ~= '' then
        Snacks.notify.error(stderr)
        if
            not stderr:match 'Warning: ' -- e.g. 'Warning: 2 uncommitted changes'
        then
            -- abort if not just a warning
            return
        end
    end

    Snacks.notify 'created PR'
    require('coop.uv-utils').sleep(2000)
    M.pr.open(opts)
end

return M
