local M = {}

---@async
---@param args string[]
---@return string stdout
local git = function(args)
    table.insert(args, 1, 'git')
    local out = require('coop.vim').system(args)
    if out.code ~= 0 then
        error(assert(out.stderr))
    end
    return vim.trim(assert(out.stdout))
end

---@return boolean
M.is_repo = function()
    return vim.uv.fs_stat '.git' and true or false
end

---@async
---@return string name of the current branch
M.current_branch = function()
    return git { 'branch', '--show-current' }
end

---@async
---@return string name of the default branch
M.default_branch = function()
    local ref = git { 'symbolic-ref', 'refs/remotes/origin/HEAD' }
    local elements = vim.split(ref, '/')
    return elements[#elements]
end

---@async
---@return string title of the last commit
M.last_commit_title = function()
    return git { 'log', '-1', '--pretty=%s' }
end

return M
