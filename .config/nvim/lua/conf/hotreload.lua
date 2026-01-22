-- source: https://github.com/richardgill/nix/blob/bdd30a0a4bb328f984275c37c7146524e99f1c22/modules/home-manager/dot-files/nvim/lua/custom/hotreload.lua
local M = {}

local watcher = require 'conf.watcher'

local function should_check()
    local mode = vim.api.nvim_get_mode().mode
    return not (
        mode:match '[cR!s]' -- Skip: command-line, replace, ex, select modes
        or vim.fn.getcmdwintype() ~= '' -- Skip: command-line window is open
    )
end

local function should_watch_buffer(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    local buftype = vim.api.nvim_get_option_value('buftype', { buf = buf })
    local is_real_file = name ~= '' and not name:match '^%w+://' -- Skip URIs like diffview://, fugitive://, etc

    return is_real_file and buftype == ''
end

local function should_reload_buffer(buf)
    local modified = vim.api.nvim_get_option_value('modified', { buf = buf })
    return should_watch_buffer(buf) and not modified
end

local function get_visible_buffers()
    local visible = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        visible[vim.api.nvim_win_get_buf(win)] = true
    end
    return visible
end

local function find_buffer_by_filepath(filepath)
    local visible_buffers = get_visible_buffers()
    for buf, _ in pairs(visible_buffers) do
        if vim.api.nvim_buf_get_name(buf) == filepath then
            return buf
        end
    end
    return nil
end

-- Track which directories we've registered for each buffer
local buf_directories = {}

local function watch_buffer(buf)
    if not should_watch_buffer(buf) then
        return
    end

    local name = vim.api.nvim_buf_get_name(buf)
    local dir = vim.fs.dirname(name)

    if dir and not buf_directories[buf] then
        if watcher.watch(dir) then
            buf_directories[buf] = dir
        end
    end
end

local function unwatch_buffer(buf)
    local dir = buf_directories[buf]
    if dir then
        watcher.unwatch(dir)
        buf_directories[buf] = nil
    end
end

-- Register handler for file changes in watched directories
watcher.register_on_change_handler('hotreload', function(filepath, events)
    if not should_check() then
        return
    end

    local buf = find_buffer_by_filepath(filepath)
    if buf and should_reload_buffer(buf) then
        vim.cmd.checktime(buf)
    end
end)

M.setup = function()
    local augroup = vim.api.nvim_create_augroup('hotreload', { clear = true })

    -- Watch directories for all currently loaded buffers
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
            watch_buffer(buf)
        end
    end

    -- Watch new buffers after file is read
    vim.api.nvim_create_autocmd('BufReadPost', {
        group = augroup,
        callback = function(args)
            watch_buffer(args.buf)
        end,
    })

    -- Unwatch buffers when they're deleted
    vim.api.nvim_create_autocmd('BufDelete', {
        group = augroup,
        callback = function(args)
            unwatch_buffer(args.buf)
        end,
    })
end

-- Stop all watching and clean up
M.stop = function()
    vim.api.nvim_del_augroup_by_name 'hotreload'
    watcher.stop_all()
    buf_directories = {}
end

-- Debug helper
M.status = function()
    return {
        watched_dirs = watcher.list_watched(),
        buf_directories = buf_directories,
    }
end

return M
