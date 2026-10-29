--- Run debugpy launch targets in the mise environment of their config root.
---
--- debugpy accepts `python` as a command list, so the debuggee is spawned via
--- `mise -C <root> exec -- python` instead of in Neovim's own environment.
---
--- debugpy starts its launcher with only `python[1]` (`mise`), which hangs the
--- session. `debugLauncherPython` works around that.
local M = {}

--- Config root that `python` (a `project.exec()` command list) runs in.
---@param python any
---@return string?
function M.exec_root(python)
    if
        type(python) == 'table'
        and python[1] == 'mise'
        and python[2] == '-C'
        and python[4] == 'exec'
    then
        return python[3]
    end
end

--- Config root of a launch config: from its `python` command, else the
--- current buffer, else `program`. nil outside monorepo config roots.
---@param config table
---@return string?
function M.root(config)
    local project = require('conf.project')
    local root = M.exec_root(config.python)
    if not root then
        local path = vim.api.nvim_buf_get_name(0)
        if path == '' and type(config.program) == 'string' then
            path = config.program
        end
        if path == '' or not vim.startswith(path, '/') then
            return nil
        end
        root = project.of(path)
    end
    if not root or root == vim.g.workspace_root then
        return nil
    end
    return root
end

--- Adjust a launch config to run in the mise env of its config root.
---@param config table
---@param cb fun(config: table) called on the main loop
function M.resolve(config, cb)
    local root = config.request == 'launch' and M.root(config)
    if not root then
        cb(config)
        return
    end
    local project = require('conf.project')
    if not config.python and not config.pythonPath then
        config.python = project.exec(root, { 'python' })
    end
    if not config.cwd or config.cwd == vim.g.workspace_root then
        config.cwd = root
    end
    local python = config.python
    if not M.exec_root(python) then
        cb(config)
        return
    end
    project.executable(root, 'python', function(path)
        -- a bare `python` can resolve to the mise shim instead of the venv
        local program = #python == 6 and python[6] or nil
        if path and (program == 'python' or program == 'python3') then
            config.python = project.exec(root, { path })
        end
        config.debugLauncherPython = config.debugLauncherPython
            or path
            or vim.fn.exepath('python3')
        cb(config)
    end)
end

--- Wrap dap-python's `python` adapter so launch configs are resolved first.
---@param dap table
function M.wrap(dap)
    local adapter_fn = dap.adapters.python
    if type(adapter_fn) ~= 'function' then
        return
    end
    dap.adapters.python = function(cb, config)
        adapter_fn(function(adapter)
            local enrich = adapter.enrich_config
            if enrich then
                adapter.enrich_config = function(cfg, on_config)
                    M.resolve(cfg, function(resolved)
                        enrich(resolved, on_config)
                    end)
                end
            end
            cb(adapter)
        end, config)
    end
    dap.adapters.debugpy = dap.adapters.python
end

return M
