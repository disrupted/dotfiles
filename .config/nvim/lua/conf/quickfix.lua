local M = {}

function M.config()
    local bqf = require 'bqf'
    bqf.setup {
        auto_enable = false,
        preview = {
            auto_preview = true,
            win_height = 12,
            win_vheight = 12,
            border_chars = {
                '┃',
                '┃',
                '━',
                '━',
                '┏',
                '┓',
                '┗',
                '┛',
                '█',
            },
            should_preview_cb = function(bufnr)
                local fname = vim.api.nvim_buf_get_name(bufnr)
                local fsize = vim.fn.getfsize(fname)
                -- disable preview if file size greater than 100k
                if fsize > 100 * 1024 then
                    return false
                end
                return true
            end,
        },
    }
    bqf.enable()
end

return M
