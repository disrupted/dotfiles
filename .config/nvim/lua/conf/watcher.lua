-- source: https://github.com/richardgill/nix/blob/bdd30a0a4bb328f984275c37c7146524e99f1c22/modules/home-manager/dot-files/nvim/lua/custom/directory-watcher.lua
local M = {}

local on_change_handlers = {}
-- Watched directories: { [path] = { fs_event, cleanup, refcount } }
local watchers = {}
local debounce_ms = 100

-- Debounce helper to prevent callback storms
local function debounce(fn, delay)
    local timer = vim.uv.new_timer()
    return function(...)
        local args = { ... }
        timer:stop()
        timer:start(
            delay,
            0,
            vim.schedule_wrap(function()
                fn(unpack(args))
            end)
        )
    end, function()
        timer:stop()
        timer:close()
    end
end

-- Register a named handler to be called when files change
-- If a handler with the same name exists, it will be replaced
-- Note: Named handlers are required to support Lua hotreload - when a file is reloaded,
-- it re-registers its handler with the same name, replacing the old one instead of
-- creating duplicates
M.register_on_change_handler = function(name, handler)
    on_change_handlers[name] = handler
end

-- Start watching a directory for file changes
-- Returns true if watcher was created or refcount incremented
M.watch = function(path)
    if not path then
        return false
    end

    -- If already watching this directory, increment refcount
    if watchers[path] then
        watchers[path].refcount = watchers[path].refcount + 1
        return true
    end

    -- Create fs_event handle
    local fs_event = vim.uv.new_fs_event()
    if not fs_event then
        return false
    end

    -- Debounced callback for file changes
    local on_change, cleanup = debounce(function(err, filename, events)
        if err then
            M.unwatch(path)
            return
        end

        if filename then
            local full_path = path .. '/' .. filename

            -- Call all registered handlers
            for _, handler in pairs(on_change_handlers) do
                pcall(handler, full_path, events)
            end
        end
    end, debounce_ms)

    -- Start watching
    local ok = fs_event:start(path, { recursive = false }, vim.schedule_wrap(on_change))

    if ok ~= 0 then
        fs_event:close()
        cleanup()
        return false
    end

    watchers[path] = {
        fs_event = fs_event,
        cleanup = cleanup,
        refcount = 1,
    }
    return true
end

-- Stop watching a directory (decrements refcount, stops when zero)
M.unwatch = function(path)
    local w = watchers[path]
    if not w then
        return
    end

    w.refcount = w.refcount - 1
    if w.refcount <= 0 then
        w.fs_event:stop()
        if not w.fs_event:is_closing() then
            w.fs_event:close()
        end
        w.cleanup()
        watchers[path] = nil
    end
end

-- Stop all watchers and clean up resources
M.stop_all = function()
    for path, w in pairs(watchers) do
        w.fs_event:stop()
        if not w.fs_event:is_closing() then
            w.fs_event:close()
        end
        w.cleanup()
        watchers[path] = nil
    end
end

-- Get list of currently watched directories (for debugging)
M.list_watched = function()
    local paths = {}
    for path, w in pairs(watchers) do
        table.insert(paths, { path = path, refcount = w.refcount })
    end
    return paths
end

return M
