local loader = require('doze.loader')

local M = {}

-- Fresh installs must finish building before setup loads anything; <C-c> or the timeout leaves the build running.
local INSTALL_TIMEOUT_MS = 10 * 60 * 1000

local jobs = 0

---@param id? integer|string
---@param name string
---@param status 'running'|'success'|'failed'
---@return integer|string|nil
local function progress(id, name, status)
    local text = status == 'running' and 'build ' .. name
        or ('build %s: %s'):format(name, status)
    local ok, new_id = pcall(vim.api.nvim_echo, { { text } }, status ~= 'running', {
        kind = 'progress',
        source = 'doze',
        title = 'doze',
        status = status,
        id = id,
    })
    return ok and new_id or id
end

---@param plugin doze.Plugin
---@param id? integer|string
---@param err? string
local function report(plugin, id, err)
    progress(id, plugin.name, err and 'failed' or 'success')
    if err then
        loader.warn(('build of %s failed: %s'):format(plugin.name, err))
    end
end

---@param plugin doze.Plugin
---@param build string|fun(plugin: doze.Plugin)
local function run_in_editor(plugin, build)
    local id = progress(nil, plugin.name, 'running')
    loader.load(plugin.name)
    local ok, err = pcall(function()
        if type(build) == 'function' then
            build(plugin)
        else
            vim.cmd(build)
        end
    end)
    report(plugin, id, not ok and tostring(err) or nil)
end

---@param plugin doze.Plugin
---@param cmd string
local function run_shell(plugin, cmd)
    local id = progress(nil, plugin.name, 'running')
    jobs = jobs + 1
    local ok, err = pcall(
        vim.system,
        { 'sh', '-c', cmd },
        { cwd = plugin.path, text = true },
        vim.schedule_wrap(function(result)
            jobs = jobs - 1
            report(
                plugin,
                id,
                result.code ~= 0
                        and ('exit %d: %s'):format(result.code, result.stderr or '')
                    or nil
            )
        end)
    )
    if not ok then
        jobs = jobs - 1
        report(plugin, id, tostring(err))
    end
end

---@param plugin doze.Plugin
function M.run(plugin)
    local build = plugin.spec.build
    if build == nil then
        return
    end
    if type(build) == 'string' and build:sub(1, 1) ~= ':' then
        return run_shell(plugin, build)
    end
    if not loader.enabled(plugin) then
        return
    end
    -- `:` commands and functions need the plugin's commands, which its plugin/ files only define after startup.
    if vim.v.vim_did_enter == 0 then
        vim.api.nvim_create_autocmd('VimEnter', {
            once = true,
            callback = function()
                run_in_editor(plugin, build)
            end,
        })
    else
        run_in_editor(plugin, build)
    end
end

---@param plugins table<string, doze.Plugin>
function M.subscribe(plugins)
    vim.api.nvim_create_autocmd('PackChanged', {
        group = vim.api.nvim_create_augroup('doze_build', { clear = true }),
        callback = function(ev)
            local kind = ev.data.kind
            local plugin = plugins[ev.data.spec.name]
            if plugin and (kind == 'install' or kind == 'update') then
                M.run(plugin)
            end
        end,
    })
end

function M.wait()
    if jobs > 0 then
        vim.wait(INSTALL_TIMEOUT_MS, function()
            return jobs == 0
        end)
    end
end

return M
