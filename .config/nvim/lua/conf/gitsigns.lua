local M = {}

function M.config()
    require('gitsigns').setup {
        signs = {
            add = {
                hl = 'GitSignsAdd',
                text = '▎', -- ▍
                numhl = 'GitSignsAddNr',
                linehl = 'GitSignsAddLn',
            },
            change = {
                hl = 'GitSignsChange',
                text = '▎',
                numhl = 'GitSignsChangeNr',
                linehl = 'GitSignsChangeLn',
            },
            delete = {
                hl = 'GitSignsDelete',
                text = '▎',
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
                text = '▎',
                show_count = true,
                numhl = 'GitSignsChangeNr',
                linehl = 'GitSignsChangeLn',
            },
            untracked = {
                hl = 'GitSignsAdd',
                text = '▍', -- ▋▎┊┆╷
                numhl = 'GitSignsAddNr',
                linehl = 'GitSignsAddLn',
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
        watch_gitdir = { interval = 1000, follow_files = true },
        attach_to_untracked = true,
        current_line_blame = false,
        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
            delay = 1000,
            ignore_whitespace = true,
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
        on_attach = function(bufnr)
            local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                vim.keymap.set(mode, l, r, opts)
            end

            local gs = package.loaded.gitsigns

            -- Navigation
            map('n', ']c', function()
                if vim.wo.diff then
                    return ']c'
                end
                vim.schedule(function()
                    gs.next_hunk()
                end)
                return '<Ignore>'
            end, { expr = true })

            map('n', '[c', function()
                if vim.wo.diff then
                    return '[c'
                end
                vim.schedule(function()
                    gs.prev_hunk()
                end)
                return '<Ignore>'
            end, { expr = true })

            -- Actions
            map({ 'n', 'v' }, '<leader>hs', gs.stage_hunk)
            map({ 'n', 'v' }, '<leader>hr', gs.reset_hunk)
            map('n', '<leader>hS', gs.stage_buffer)
            map('n', '<leader>hu', gs.undo_stage_hunk)
            map('n', '<leader>hR', gs.reset_buffer)
            map('n', '<leader>hp', gs.preview_hunk)
            map('n', '<leader>hb', gs.toggle_current_line_blame)
            map('n', '<leader>hd', gs.diffthis)
            map('n', '<leader>hD', function()
                gs.diffthis '~'
            end)

            -- Text object
            map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
        end,
    }

    -- vim.cmd [[autocmd User FormatterPost lua require'gitsigns'.refresh()]]
end

return M
