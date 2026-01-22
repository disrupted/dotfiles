-- source: https://github.com/richardgill/nix/blob/bdd30a0a4bb328f984275c37c7146524e99f1c22/modules/home-manager/dot-files/nvim/lua/custom/hotreload.lua
local M = {}

local function should_check()
    local mode = vim.api.nvim_get_mode().mode
    return not (
        mode:match '[cR!s]' -- Skip: command-line, replace, ex, select modes
        or vim.fn.getcmdwintype() ~= '' -- Skip: command-line window is open
    )
end

local function should_reload_buffer(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    local buftype = vim.api.nvim_get_option_value('buftype', { buf = buf })
    local modified = vim.api.nvim_get_option_value('modified', { buf = buf })
    local is_real_file = name ~= '' and not name:match '^%w+://' -- Skip URIs like diffview://, fugitive://, etc

    return is_real_file and buftype == '' and not modified
end

local function get_visible_buffers()
    local visible = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        visible[vim.api.nvim_win_get_buf(win)] = true
    end
    return visible
end

local find_buffer_by_filepath = function(filepath)
    local visible_buffers = get_visible_buffers()
    for buf, _ in pairs(visible_buffers) do
        if vim.api.nvim_buf_get_name(buf) == filepath then
            return buf
        end
    end
    return nil
end

-- Register handler for file changes in watched directory
require('conf.watcher').register_on_change_handler(
    'hotreload',
    function(filepath, events)
        if not should_check() then
            return
        end

        local buf = find_buffer_by_filepath(filepath)
        if buf and should_reload_buffer(buf) then
            vim.cmd.checktime(buf)
        end
    end
)

M.setup = function(opts)
    require('conf.watcher').setup {
        path = opts.path,
    }

    --     vim.api.nvim_create_autocmd({
    --         'FocusGained',
    --         'TermLeave',
    --         'BufEnter',
    --         'WinEnter',
    --         'CursorHold',
    --         'CursorHoldI',
    --     }, {
    --         group = vim.api.nvim_create_augroup('hotreload', { clear = true }),
    --         callback = function()
    --             if should_check() then
    --                 vim.cmd.checktime()
    --             end
    --         end,
    --     })
end

return M
