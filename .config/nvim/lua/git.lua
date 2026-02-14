local M = {}

local refresh_timer = assert(vim.uv.new_timer())
local refresh_debounce_ms = 150
local refresh_running = false
local refresh_queued = false
local refresh_scheduled = false
local metrics = {
    refresh_requested = 0,
    refresh_started = 0,
    refresh_completed = 0,
    refresh_coalesced = 0,
    file_change_events = 0,
    last_refresh_started_at = nil,
    last_refresh_completed_at = nil,
    last_refresh_duration_ms = nil,
}

local last_refresh_started_ms
local last_refresh_completed_ms

local function now_ms()
    return math.floor(vim.uv.hrtime() / 1e6)
end

local function now_localtime()
    return os.date '%Y-%m-%d %H:%M:%S'
end

---@param ts_ms integer?
---@return string?
local function age_from_now(ts_ms)
    if not ts_ms then
        return nil
    end
    local delta = math.max(0, now_ms() - ts_ms)
    if delta < 1000 then
        return ('%dms ago'):format(delta)
    end

    local sec = math.floor(delta / 1000)
    if sec < 60 then
        return ('%ds ago'):format(sec)
    end

    local min = math.floor(sec / 60)
    sec = sec % 60
    if min < 60 then
        return ('%dm %ds ago'):format(min, sec)
    end

    local hrs = math.floor(min / 60)
    min = min % 60
    return ('%dh %dm ago'):format(hrs, min)
end

---@param args string[]
---@return string stdout
local function git(args)
    local out = vim.system({ 'git', '--git-dir', vim.g.git_repo, unpack(args) })
        :wait()
    if out.code ~= 0 then
        error(assert(out.stderr))
    end
    return vim.trim(assert(out.stdout))
end

---@param cwd string
---@return string?
M.find_repo = function(cwd)
    local out = vim.system({
        'git',
        '-C',
        cwd,
        'rev-parse',
        '--absolute-git-dir',
    }):wait()
    if out.code == 0 and out.stdout and out.stdout ~= '' then
        return vim.trim(out.stdout)
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
    metrics.refresh_requested = metrics.refresh_requested + 1
    if refresh_running then
        metrics.refresh_coalesced = metrics.refresh_coalesced + 1
        refresh_queued = true
        return
    end

    refresh_scheduled = false
    refresh_running = true
    metrics.refresh_started = metrics.refresh_started + 1
    last_refresh_started_ms = now_ms()
    metrics.last_refresh_started_at = now_localtime()
    require('coop').spawn(function()
        local remote_url = M.async.remote_url()
        if remote_url and remote_url ~= '' then
            vim.g.git_remote_type = M.match_remote_type(remote_url)
        else
            vim.g.git_remote_type = nil
        end

        vim.g.git_branch = M.async.current_branch()
        if not vim.g.git_branch then
            vim.g.git_head = M.async.head()
        end

        if vim.g.git_remote_type == 'github' then
            local ok, err = pcall(require('gh').pr.refresh)
            if not ok then
                Snacks.notify.error(
                    { err },
                    { title = 'GitHub PR refresh failed' }
                )
            end
        elseif vim.g.git_remote_type == 'gitlab' then
            local ok, err = pcall(require('glab').mr.refresh)
            if not ok then
                Snacks.notify.error(
                    { err },
                    { title = 'GitLab MR refresh failed' }
                )
            end
        end

        vim.api.nvim_exec_autocmds('User', {
            pattern = 'GitRefresh',
            modeline = false,
        })

        refresh_running = false
        metrics.refresh_completed = metrics.refresh_completed + 1
        last_refresh_completed_ms = now_ms()
        metrics.last_refresh_completed_at = now_localtime()
        if last_refresh_started_ms then
            metrics.last_refresh_duration_ms = last_refresh_completed_ms
                - last_refresh_started_ms
        end
        if refresh_queued then
            refresh_queued = false
            vim.schedule(M.refresh)
        end
    end)
end

local function schedule_refresh()
    refresh_scheduled = true
    refresh_timer:stop()
    refresh_timer:start(
        refresh_debounce_ms,
        0,
        vim.schedule_wrap(function()
            M.refresh()
        end)
    )
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

    metrics.file_change_events = metrics.file_change_events + 1
    Snacks.notify(
        { ('%s changed'):format(filename), vim.inspect(events) },
        { title = 'Git', level = 'debug' }
    )

    -- git may replace .git/HEAD atomically; restart watcher after each event
    M.watch()
    schedule_refresh()
end

M.debug_status = function()
    local coalesced_pct = 0
    if metrics.refresh_requested > 0 then
        coalesced_pct = math.floor(
            (metrics.refresh_coalesced / metrics.refresh_requested) * 100
        )
    end

    return {
        git_repo = vim.g.git_repo,
        git_remote_type = vim.g.git_remote_type,
        git_branch = vim.g.git_branch,
        git_head = vim.g.git_head,
        watcher = {
            active = watcher ~= nil,
            closing = watcher and watcher:is_closing() or false,
        },
        refresh = {
            running = refresh_running,
            queued = refresh_queued,
            scheduled = refresh_scheduled,
            debounce_ms = refresh_debounce_ms,
        },
        metrics = {
            refresh_requested = metrics.refresh_requested,
            refresh_started = metrics.refresh_started,
            refresh_completed = metrics.refresh_completed,
            refresh_coalesced = ('%d (%d%% of requested)'):format(
                metrics.refresh_coalesced,
                coalesced_pct
            ),
            file_change_events = metrics.file_change_events,
            last_refresh_started = metrics.last_refresh_started_at,
            last_refresh_started_age = age_from_now(last_refresh_started_ms),
            last_refresh_completed = metrics.last_refresh_completed_at,
            last_refresh_completed_age = age_from_now(
                last_refresh_completed_ms
            ),
            last_refresh_duration = metrics.last_refresh_duration_ms
                    and ('%dms'):format(metrics.last_refresh_duration_ms)
                or nil,
        },
    }
end

M.debug_status_reset = function()
    metrics = {
        refresh_requested = 0,
        refresh_started = 0,
        refresh_completed = 0,
        refresh_coalesced = 0,
        file_change_events = 0,
        last_refresh_started_at = nil,
        last_refresh_completed_at = nil,
        last_refresh_duration_ms = nil,
    }
    last_refresh_started_ms = nil
    last_refresh_completed_ms = nil
end

---@param action? string
M.debug_command = function(action)
    if action == 'reset' then
        M.debug_status_reset()
        return
    end

    Snacks.notify(vim.inspect(M.debug_status()), {
        title = 'Git',
    })
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
        watcher:stop()
        watcher:close()
    end
    watcher = nil
end

---@param cwd string
M.setup = function(cwd)
    vim.g.git_repo = M.find_repo(cwd)
    if vim.g.git_repo then
        M.watch()
        vim.api.nvim_create_autocmd('DirChanged', {
            callback = function(args)
                local new_cwd = args.file ~= '' and args.file or vim.fn.getcwd()
                local new_repo = M.find_repo(new_cwd)
                if new_repo ~= vim.g.git_repo then
                    vim.g.git_repo = new_repo
                    if new_repo then
                        M.watch()
                    else
                        M.close()
                    end
                end
                if vim.g.git_repo then
                    schedule_refresh()
                end
            end,
            desc = 'Reinitialize Git watcher on cwd changes',
        })
        vim.api.nvim_create_autocmd(
            'VimLeavePre',
            { callback = M.close, desc = 'Close Git watcher' }
        )
        schedule_refresh()
    end
end

---@async
---@param args string[]
---@return string? stdout
local function git_async(args)
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
---@return string? name of the default branch
M.async.default_branch = function()
    local ref = git_async { 'symbolic-ref', 'refs/remotes/origin/HEAD' }
    if not ref then
        return
    end
    local elements = vim.split(ref, '/')
    return elements[#elements]
end

---@async
---@return string title of the last commit
M.async.last_commit_title = function()
    return git_async { 'log', '-1', '--pretty=%s' }
end

return M
