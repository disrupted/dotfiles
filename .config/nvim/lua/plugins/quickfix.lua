---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'stevearc/quicker.nvim',
        ft = 'qf',
        init = function()
            require('which-key').add {
                {
                    '<Leader>q',
                    function()
                        require('quicker').toggle()
                    end,
                    desc = 'Toggle QuickFix list',
                    icon = require('conf.icons').misc.quickfix,
                },
            }
        end,
        ---@module 'quicker'
        ---@type quicker.SetupOptions
        opts = {
            opts = { winhighlight = 'CursorLine:Visual,Delimiter:WinSeparator' },
            borders = { vert = ' ' },
            -- TODO: can we enable this with async TreeSitter
            -- highlight = {
            --     -- Load the referenced buffers to apply more accurate highlights (may be slow)
            --     load_buffers = true,
            -- },
            max_filename_width = function()
                return math.floor(math.min(95, vim.o.columns / 2))
            end,
        },
    },
    {
        'kevinhwang91/nvim-bqf',
        ft = 'qf',
        ---@module 'bqf.config'
        ---@type BqfConfig
        opts = {
            auto_enable = true,
            auto_resize_height = true,
            ---@diagnostic disable-next-line: missing-fields
            preview = {
                auto_preview = true,
                win_height = 12,
                win_vheight = 12,
                should_preview_cb = function(bufnr)
                    local fname = vim.api.nvim_buf_get_name(bufnr)
                    local stat = vim.uv.fs_stat(fname)
                    if not stat or stat.size > 100 * 1024 then
                        -- disable preview if file does not exist or size greater than 100k
                        -- TODO: still needed with async TreeSitter?
                        return false
                    end
                    return true
                end,
            },
        },
    },
}
