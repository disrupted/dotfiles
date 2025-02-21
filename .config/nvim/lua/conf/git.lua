local M = {}

---@async
---@param args string[]
---@return string stdout
local git = function(args)
    local process = require('nio').process.run {
        cmd = 'git',
        args = args,
    }
    assert(process)
    if process.result(false) ~= 0 then
        local stderr = assert(process.stderr.read())
        error(stderr)
    end
    local stdout = assert(process.stdout.read())
    process.close()
    return vim.trim(stdout)
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
