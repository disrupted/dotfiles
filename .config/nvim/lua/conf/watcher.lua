-- source: https://github.com/richardgill/nix/blob/bdd30a0a4bb328f984275c37c7146524e99f1c22/modules/home-manager/dot-files/nvim/lua/custom/directory-watcher.lua
local M = {}

local watcher = nil
local cleanup_debounce = nil
local on_change_handlers = {}

-- Debounce helper to prevent callback storms
local debounce = function(fn, delay)
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
M.setup = function(opts)
    opts = opts or {}
    local path = opts.path

    if not path then
        return false
    end

    -- Stop existing watcher if any
    if watcher then
        M.stop()
    end

    -- Create fs_event handle
    local fs_event = vim.uv.new_fs_event()
    if not fs_event then
        return false
    end

    -- Debounced callback for file changes
    local on_change, cleanup = debounce(function(err, filename, events)
        if err then
            M.stop()
            return
        end

        if filename then
            local full_path = path .. '/' .. filename

            -- Call all registered handlers
            for _, handler in pairs(on_change_handlers) do
                pcall(handler, full_path, events)
            end
        end
    end, opts.debounce or 100)
    cleanup_debounce = cleanup

    -- Start watching (wrapped for thread safety)
    local ok, err = fs_event:start(
        path,
        { recursive = false },
        vim.schedule_wrap(on_change)
    )

    if ok ~= 0 then
        return false
    end

    watcher = fs_event
    return true
end

-- Stop the watcher and clean up resources
M.stop = function()
    if watcher then
        watcher:stop()
        watcher = nil
    end

    if cleanup_debounce then
        cleanup_debounce()
        cleanup_debounce = nil
    end
end

return M
