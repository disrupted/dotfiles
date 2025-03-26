local M = {}

local glab = {
    ---@async
    ---@param opts table
    ---@return string? out
    run = function(opts)
        local cmd = opts.args
        table.insert(cmd, 1, 'glab')
        local out = require('coop.vim').system(cmd)
        -- assert(out.code == 0)
        return out.stdout
    end,
}

M.mr = {}

---@async
---@return table<string, any>?
M.mr.json = function()
    local out = glab.run { args = { 'mr', 'view', '--output', 'json' } } or ''
    out = vim.trim(out)
    if out ~= '' then
        return vim.json.decode(out)
    end
end

---@async
---@return boolean
M.mr.exists = function()
    return M.mr.json() and true or false
end

---@async
M.mr.refresh = function()
    -- align schema with gh CLI so that it is uniform and easier to consume
    ---@param json table<string, any>?
    ---@return table<string, any>?
    local function transform(json)
        if not json then
            return
        end
        -- https://gitlab.com/gitlab-org/cli/-/blob/main/commands/mr/mrutils/mrutils.go
        local state_map = {
            opened = 'OPEN',
            draft = 'OPEN',
            -- closed
            -- merged
        }
        json.state = state_map[json.state]
        return json
    end

    if vim.g.git_branch then
        vim.g.git_pr = transform(M.mr.json())
    else
        vim.g.git_pr = nil
    end
end

return M
