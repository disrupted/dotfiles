local M = {}

function M.setup()
    vim.cmd [[packadd gitsigns.nvim]]
    require'gitsigns'.setup {
        signs = {
            add = {hl = 'DiffAdd', text = '+', numhl = 'GitSignsAddNr'},
            change = {hl = 'DiffChange', text = '~', numhl = 'GitSignsChangeNr'},
            delete = {
                hl = 'DiffDelete',
                text = '_',
                show_count = true,
                numhl = 'GitSignsDeleteNr'
            },
            topdelete = {
                hl = 'DiffDelete',
                text = '‾',
                show_count = true,
                numhl = 'GitSignsDeleteNr'
            },
            changedelete = {
                hl = 'DiffChange',
                text = '~',
                show_count = true,
                numhl = 'GitSignsChangeNr'
            }
        },
        count_chars = {
            [1] = '',
            [2] = '₂',
            [3] = '₃',
            [4] = '₄',
            [5] = '₅',
            [6] = '₆',
            [7] = '₇',
            [8] = '₈',
            [9] = '₉',
            ['+'] = '₊'
        },
        numhl = false,
        keymaps = {
            -- Default keymap options
            noremap = true,
            buffer = true,

            ['n ]c'] = {
                expr = true,
                "&diff ? ']c' : '<cmd>lua require\"gitsigns\".next_hunk()<CR>'"
            },
            ['n [c'] = {
                expr = true,
                "&diff ? '[c' : '<cmd>lua require\"gitsigns\".prev_hunk()<CR>'"
            },

            ['n <leader>hs'] = '<cmd>lua require"gitsigns".stage_hunk()<CR>',
            ['n <leader>hu'] = '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>',
            ['n <leader>hr'] = '<cmd>lua require"gitsigns".reset_hunk()<CR>',
            ['n <leader>hp'] = '<cmd>lua require"gitsigns".preview_hunk()<CR>',
            ['n <leader>hb'] = '<cmd>lua require"gitsigns".blame_line()<CR>'
        },
        watch_index = {interval = 1000},
        sign_priority = 6,
        status_formatter = nil, -- Use default
        yadm = {enable = true}
    }
end

return M
