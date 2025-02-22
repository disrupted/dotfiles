local M = {}

local nio = require 'nio'

M.pr = {}

local gh = {
    ---@async
    ---@param opts table
    ---@return string? out
    run = function(opts)
        return nio.wrap(function(cb)
            opts.cb = cb
            require('octo.gh').run(opts)
        end, 1)()
    end,
    pr = {
        ---@async
        ---@param opts table
        ---@return string? out
        ---@return string? stderr
        create = function(opts)
            return nio.wrap(function(cb)
                opts = vim.tbl_deep_extend('keep', opts, { opts = { cb = cb } })
                require('octo.gh').pr.create(opts)
            end, 1)()
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
    -- local last_commit_title = require('git').last_commit_title()

    local title = nio.ui.input {
        prompt = 'PR title',
        -- default = last_commit_title,
        win = { ft = 'gitcommit' },
    }
    if not title or title == '' then
        return
    end

    local body = nio.ui.input {
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
    nio.sleep(2000)
    M.pr.open(opts)
end

return M
