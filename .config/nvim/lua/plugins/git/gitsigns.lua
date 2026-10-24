---@type LazeSpec
return {
    'lewis6991/gitsigns.nvim',
    main = 'gitsigns',
    module = 'gitsigns',
    event = { 'BufWinEnter', 'BufNewFile' },
    init = function()
        require('which-key').add({
            {
                '<Leader>g',
                mode = { 'n', 'v' },
                group = 'Git',
                icon = '',
            },
        })
    end,
    ---@module 'gitsigns.config'
    ---@type Gitsigns.Config
    ---@diagnostic disable-next-line: missing-fields
    opts = {
        ---@diagnostic disable-next-line: missing-fields
        diff_opts = {
            -- Include whitespace-only changes in git hunks regardless of 'diffopt'
            ignore_whitespace_change = false,
            ignore_blank_lines = false,
            ignore_whitespace = false,
            ignore_whitespace_change_at_eol = false,
        },
        signs = {
            add = {
                text = '▎', -- ▍
                show_count = false,
            },
            change = {
                text = '▎',
                show_count = false,
            },
            delete = {
                text = '▎',
                show_count = true,
            },
            topdelete = {
                text = '‾',
                show_count = true,
            },
            changedelete = {
                text = '▎',
                show_count = true,
            },
            untracked = {
                text = '▍', -- ▋▎┊┆╷
                show_count = false,
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
        attach_to_untracked = true,
        current_line_blame = false,
        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = 'right_align', -- 'eol' | 'overlay' | 'right_align'
            delay = 1000,
            ignore_whitespace = true,
        },
        sign_priority = 9999,
        update_debounce = 100,
        ---@diagnostic disable-next-line: assign-type-mismatch
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
        trouble = false,
        on_attach = function(bufnr)
            local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                vim.keymap.set(mode, l, r, opts)
            end

            local gs = package.loaded.gitsigns
            ---@cast gs gitsigns.main

            ---@diagnostic disable-next-line: missing-fields
            local nav_opts = { target = 'all' } --[[@as Gitsigns.NavOpts]]

            -- Navigation
            map('n', ']g', function()
                if vim.wo.diff then
                    vim.cmd.normal({ ']g', bang = true })
                else
                    gs.nav_hunk('next', nav_opts)
                end
            end, { desc = 'Next Git hunk' })
            map('n', '[g', function()
                if vim.wo.diff then
                    vim.cmd.normal({ '[g', bang = true })
                else
                    gs.nav_hunk('prev', nav_opts)
                end
            end, { desc = 'Prev Git hunk' })
            -- map('n', ']s', function()
            --     if vim.wo.diff then
            --         vim.cmd.normal { ']s', bang = true }
            --     else
            --         gs.nav_hunk('next', { target = 'staged' })
            --     end
            -- end, { desc = 'Next staged hunk' })
            -- map('n', '[s', function()
            --     if vim.wo.diff then
            --         vim.cmd.normal { '[s', bang = true }
            --     else
            --         gs.nav_hunk('prev', { target = 'staged' })
            --     end
            -- end, { desc = 'Prev staged hunk' })
            map('n', '<Leader>gs', gs.stage_hunk, { desc = 'Stage hunk' })
            map('v', '<Leader>gs', function()
                gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
            end, { desc = 'Stage hunk' })
            map('n', '<Leader>gr', gs.reset_hunk, { desc = 'Reset hunk' })
            map('v', '<Leader>gr', function()
                gs.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
            end, { desc = 'Reset hunk' })
            map('n', '<Leader>gS', gs.stage_buffer, { desc = 'Stage buffer' })
            map('n', '<Leader>gR', gs.reset_buffer, { desc = 'Reset buffer' })
            map('n', '<Leader>gh', gs.preview_hunk, { desc = 'Preview hunk' })
            map('n', '<Leader>gb', gs.toggle_current_line_blame, { desc = 'Blame' })
            -- map(
            --     'n',
            --     '<Leader>gd',
            --     gs.diffthis,
            --     { desc = 'Diff against index' }
            -- )
            -- map('n', '<Leader>gD', function()
            --     gs.diffthis '~'
            -- end, {
            --     desc = 'Diff against last commit',
            -- })

            -- Text object
            map(
                { 'o', 'x' },
                'ih',
                ':<C-U>Gitsigns select_hunk<CR>',
                { desc = 'Select Git hunk' }
            )
        end,
    },
}
