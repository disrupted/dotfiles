local M = {}

---@async
---@param args string[]
---@return string? stdout
local git = function(args)
    local cmd = { 'git' }
    vim.list_extend(cmd, args)
    local out = require('coop.vim').system(cmd, { text = true, stderr = false })
    return out.code == 0 and vim.trim(assert(out.stdout)) or nil
end

---@async
---@return string? title of the last commit
M.last_commit_title = function()
    return git { 'log', '-1', '--pretty=%s' }
end

return M
