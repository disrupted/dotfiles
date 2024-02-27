return {
    {
        'lewis6991/gitsigns.nvim',
        event = { 'BufWinEnter', 'BufNewFile' },
        opts = function()
            return {
                signs = {
                    add = {
                        text = '▎', -- ▍
                    },
                    change = {
                        text = '▎',
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
                _signs_staged_enable = true,
                _signs_staged = {
                    add = {
                        text = '┃',
                    },
                    change = {
                        text = '┃',
                    },
                    delete = {
                        text = '▁',
                    },
                    topdelete = {
                        text = '▔',
                    },
                    changedelete = {
                        text = '~',
                    },
                },
            }
        end,
    },
    {
        'NeogitOrg/neogit',
        keys = {
            {
                '<leader>g',
                function()
                    require('neogit').open()
                end,
            },
            {
                '<leader>c',
                function()
                    require('neogit').open { 'commit' }
                end,
            },
        },
        opts = {
            disable_hint = true,
            disable_commit_confirmation = true,
            signs = {
                section = { '', '' },
                item = { '', '' },
                hunk = { '', '' },
            },
            integrations = {
                diffview = true,
            },
        },
    },
    {
        'akinsho/git-conflict.nvim',
        event = 'VeryLazy',
        keys = {
            { '<leader>co', '<Plug>(git-conflict-ours)' },
            { '<leader>ct', '<Plug>(git-conflict-theirs)' },
            { '<leader>cb', '<Plug>(git-conflict-both)' },
            { '<leader>c0', '<Plug>(git-conflict-none)' },
            { '[x', '<Plug>(git-conflict-prev-conflict)' },
            { ']x', '<Plug>(git-conflict-next-conflict)' },
        },
        opts = { default_mappings = false },
        config = function(_, opts)
            require('git-conflict').setup(opts)
        end,
    },
    {
        'sindrets/diffview.nvim',
        cmd = { 'DiffviewFileOpen', 'DiffviewFileHistory' },
        opts = { enhanced_diff_hl = true },
    },
    {
        'pwntester/octo.nvim',
        cmd = 'Octo',
        keys = {
            {
                '<leader>op',
                function()
                    local url =
                        vim.fn.system 'gh pr view --json url --jq .url 2>/dev/null'
                    if url then
                        vim.notify(url)
                        local cmd = string.format('Octo %s', url)
                        vim.cmd(cmd)
                    else
                        vim.cmd 'Octo pr list'
                    end
                end,
            },
            { '<leader>oi', '<cmd>Octo issue list<cr>' },
        },
        opts = { date_format = '%Y %b %d %H:%M' },
    },
    {
        'topaxi/gh-actions.nvim',
        cmd = 'GhActions',
        build = 'make',
        dependencies = { 'nvim-lua/plenary.nvim', 'MunifTanjim/nui.nvim' },
        config = true,
    },
    {
        'harrisoncramer/gitlab.nvim',
        lazy = true,
        dependencies = {
            'MunifTanjim/nui.nvim',
            'nvim-lua/plenary.nvim',
            'sindrets/diffview.nvim',
        },
        build = function()
            require('gitlab.server').build(true)
        end,
        config = true,
    },
    {
        'linrongbin16/gitlinker.nvim',
        cmd = 'GitLink',
        keys = {
            {
                '<leader>hl',
                '<cmd>GitLink<cr>',
                mode = { 'n', 'v' },
                desc = 'Copy git permlink to clipboard',
            },
        },
        config = true,
    },
}
