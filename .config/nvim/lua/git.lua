local M = {}

---@param args string[]
---@return string stdout
local git = function(args)
    local cmd = { 'git', '--git-dir', vim.g.git_repo }
    vim.list_extend(cmd, args)
    local out = vim.system(cmd):wait()
    if out.code ~= 0 then
        error(assert(out.stderr))
    end
    return vim.trim(assert(out.stdout))
end

---@param cwd string
---@return string?
M.find_repo = function(cwd)
    local root = Snacks.git.get_root(cwd)
    if root then
        return vim.fs.joinpath(root, '.git')
    end
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

---@param remote_url string
---@return 'github' | 'gitlab'
M.match_remote_type = function(remote_url)
    if remote_url:match 'github%.com' then
        return 'github'
    end
    -- others are usually self-hosted GitLab instances in my use case
    return 'gitlab'
end

M.refresh = function()
    require('coop').spawn(function()
        local remote_url = M.async.remote_url()
        vim.g.git_remote_type = M.match_remote_type(remote_url)
        vim.g.git_branch = M.async.current_branch()
        if not vim.g.git_branch then
            vim.g.git_head = M.async.head()
        end
        if vim.g.git_remote_type == 'github' then
            require('gh').pr.refresh()
        elseif vim.g.git_remote_type == 'gitlab' then
            require('glab').mr.refresh()
        end
        vim.api.nvim_exec_autocmds('User', {
            pattern = 'GitRefresh',
            modeline = false,
        })
    end)
end

---@type uv.uv_fs_event_t
local watcher

---@type uv.fs_event_start.callback
local function on_file_change(err, filename, events)
    if err then
        Snacks.notify.error(
            { ('Error watching %s'):format(filename), err },
            { title = 'Git' }
        )
        return
    end

    Snacks.notify(
        { ('%s changed'):format(filename), vim.inspect(events) },
        { title = 'Git', level = 'debug' }
    )
    M.refresh()
    M.watch() -- restart watcher
end

M.watch = function()
    M.close()
    watcher = assert(vim.uv.new_fs_event())
    local file_to_watch = vim.g.git_repo .. '/HEAD'
    watcher:start(file_to_watch, {}, vim.schedule_wrap(on_file_change))
    Snacks.notify(
        { ('initialized watcher on %s'):format(file_to_watch) },
        { title = 'Git', level = 'debug' }
    )
end

M.close = function()
    if watcher and not watcher:is_closing() then
        watcher:close()
    end
end

---@param cwd string
M.setup = function(cwd)
    vim.g.git_repo = M.find_repo(cwd) -- TODO: DirChanged autocmd?
    if vim.g.git_repo then
        M.watch()
        vim.api.nvim_create_autocmd(
            'VimLeavePre',
            { callback = M.close, desc = 'Close Git watcher' }
        )
    end
    vim.defer_fn(M.refresh, 0)
end

---@async
---@param args string[]
---@return string? stdout
local git_async = function(args)
    local cmd = { 'git', '--git-dir', vim.g.git_repo }
    vim.list_extend(cmd, args)
    local out = require('coop.vim').system(cmd)
    if out.code == 0 and out.stdout and out.stdout ~= '' then
        return vim.trim(out.stdout)
    end
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
---@return string
M.async.head = function()
    return git_async { 'rev-parse', '--short', 'HEAD' }
end

---@async
---@return string? name of the upstream tracking branch 'origin/...'
---errors: fatal: no upstream configured for branch '...'
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
