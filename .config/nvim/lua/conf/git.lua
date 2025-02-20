local M = {}

---@param args string[]
---@return string? stdout
local git = function(args)
    local cmd = { 'git' }
    vim.list_extend(cmd, args)
    local git_result = vim.system(cmd, { text = true, stderr = false }):wait()
    return git_result.code == 0 and vim.trim(assert(git_result.stdout)) or nil
end

---@return string? title of the last commit
M.last_commit_msg = function()
    return git { 'log', '-1', '--pretty=%s' }
end

return M
