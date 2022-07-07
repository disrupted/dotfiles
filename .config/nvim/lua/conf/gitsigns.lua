local M = {}

function M.config()
    require('gitsigns').setup {
        signs = {
            add = {
                hl = 'GitSignsAdd',
                text = '▍',
                numhl = 'GitSignsAddNr',
                linehl = 'GitSignsAddLn',
            },
            change = {
                hl = 'GitSignsChange',
                text = '▍',
                numhl = 'GitSignsChangeNr',
                linehl = 'GitSignsChangeLn',
            },
            delete = {
                hl = 'GitSignsDelete',
                text = '▍',
                show_count = true,
                numhl = 'GitSignsDeleteNr',
                linehl = 'GitSignsDeleteLn',
            },
            topdelete = {
                hl = 'GitSignsDelete',
                text = '‾',
                show_count = true,
                numhl = 'GitSignsDeleteNr',
                linehl = 'GitSignsDeleteLn',
            },
            changedelete = {
                hl = 'GitSignsChange',
                text = '▍',
                show_count = true,
                numhl = 'GitSignsChangeNr',
                linehl = 'GitSignsChangeLn',
            },
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
            ['+'] = '₊',
        },
        signcolumn = true,
        numhl = false,
        linehl = false,
        word_diff = false,
        keymaps = {
            -- Default keymap options
            noremap = true,
            buffer = true,

            ['n ]c'] = {
                expr = true,
                '&diff ? \']c\' : \'<cmd>lua require"gitsigns".next_hunk()<CR>\'',
            },
            ['n [c'] = {
                expr = true,
                '&diff ? \'[c\' : \'<cmd>lua require"gitsigns".prev_hunk()<CR>\'',
            },

            ['n <leader>hs'] = '<cmd>lua require"gitsigns".stage_hunk()<CR>',
            ['v <leader>hs'] = '<cmd>lua require"gitsigns".stage_hunk({vim.fn.line("."), vim.fn.line("v")})<CR>',
            ['n <leader>hu'] = '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>',
            ['n <leader>hr'] = '<cmd>lua require"gitsigns".reset_hunk()<CR>',
            ['v <leader>hr'] = '<cmd>lua require"gitsigns".reset_hunk({vim.fn.line("."), vim.fn.line("v")})<CR>',
            ['n <leader>hR'] = '<cmd>lua require"gitsigns".reset_buffer()<CR>',
            ['n <leader>hp'] = '<cmd>lua require"gitsigns".preview_hunk()<CR>',
            ['n <leader>hb'] = '<cmd>lua require"gitsigns".blame_line()<CR>',
            ['n <leader>hS'] = '<cmd>lua require"gitsigns".stage_buffer()<CR>',
            ['n <leader>hU'] = '<cmd>lua require"gitsigns".reset_buffer_index()<CR>',

            -- Text objects
            ['o ih'] = ':<C-U>lua require"gitsigns.actions".select_hunk()<CR>',
            ['x ih'] = ':<C-U>lua require"gitsigns.actions".select_hunk()<CR>',
        },
        watch_gitdir = { interval = 1000, follow_files = true },
        attach_to_untracked = true,
        current_line_blame = false,
        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
            delay = 1000,
        },
        current_line_blame_formatter_opts = {
            relative_time = false,
        },
        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil, -- Use default
        max_file_length = 40000,
        preview_config = {
            -- Options passed to nvim_open_win
            border = 'single',
            style = 'minimal',
            relative = 'cursor',
            row = 0,
            col = 1,
        },
        yadm = { enable = true },
        trouble = false,
    }

    -- vim.cmd [[autocmd User FormatterPost lua require'gitsigns'.refresh()]]
end

return M
