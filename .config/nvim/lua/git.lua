local M = {}

---@param args string[]
---@return string stdout
local git = function(args)
    table.insert(args, 1, 'git')
    local out = vim.system(args):wait()
    if out.code ~= 0 then
        error(assert(out.stderr))
    end
    return vim.trim(assert(out.stdout))
end

---@param remote? string
---@return string
M.remote_url = function(remote)
    return git { 'remote', 'get-url', remote or 'origin' }
end

---@return string name of the current branch
M.current_branch = function()
    return git { 'branch', '--show-current' }
end

---@return boolean
M.is_repo = function()
    return vim.uv.fs_stat '.git' ~= nil
end

---@param remote_url string
---@return 'github' | 'gitlab'
M.match_remote_type = function(remote_url)
    if remote_url:match 'github%.com' then
        return 'github'
    end
    -- others are usually self-hosted GitLab instances in my use case
    return 'gitlab'
end

---@async
---@param args string[]
---@return string stdout
local git_async = function(args)
    table.insert(args, 1, 'git')
    local out = require('coop.vim').system(args)
    if out.code ~= 0 then
        error(assert(out.stderr))
    end
    return vim.trim(assert(out.stdout))
end

M.async = {}

---@async
---@param remote? string
---@return string
M.async.remote_url = function(remote)
    return git_async { 'remote', 'get-url', remote or 'origin' }
end

---@async
---@return string name of the current branch
M.async.current_branch = function()
    return git_async { 'branch', '--show-current' }
end

---@async
---@return string name of the upstream tracking branch 'origin/...'
M.async.tracking_branch = function()
    return git_async {
        'rev-parse',
        '--abbrev-ref',
        '--symbolic-full-name',
        '@{u}',
    }
end

---@async
---@return string name of the default branch
M.async.default_branch = function()
    local ref = git_async { 'symbolic-ref', 'refs/remotes/origin/HEAD' }
    local elements = vim.split(ref, '/')
    return elements[#elements]
end

---@async
---@return string title of the last commit
M.async.last_commit_title = function()
    return git_async { 'log', '-1', '--pretty=%s' }
end

return M
