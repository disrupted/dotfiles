---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'lewis6991/gitsigns.nvim',
        event = { 'BufWinEnter', 'BufNewFile' },
        dependencies = { 'purarue/gitsigns-yadm.nvim' },
        init = function()
            require('which-key').add { { '<leader>h', group = 'Git' } }
        end,
        ---@module 'gitsigns.config'
        ---@type Gitsigns.Config
        ---@diagnostic disable: missing-fields
        opts = {
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
            _on_attach_pre = function(bufnr, callback)
                local ignore_filetypes = {
                    'gitcommit', -- YADM commit
                    'gitrebase', -- YADM rebase
                }
                if
                    vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype)
                then
                    return -- do not attach to buffers of this filetype
                end
                require('gitsigns-yadm').yadm_signs(callback, { bufnr = bufnr })
            end,
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

                map(
                    'n',
                    '<leader>hs',
                    gs.stage_hunk,
                    { desc = 'Git stage hunk' }
                )
                map('v', '<leader>hs', function()
                    gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
                end, { desc = 'Git stage hunk' })
                map(
                    'n',
                    '<leader>hr',
                    gs.reset_hunk,
                    { desc = 'Git reset hunk' }
                )
                map('v', '<leader>hr', function()
                    gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
                end, { desc = 'Git reset hunk' })
                map(
                    'n',
                    '<leader>hS',
                    gs.stage_buffer,
                    { desc = 'Git stage buffer' }
                )
                map(
                    'n',
                    '<leader>hu',
                    gs.stage_hunk,
                    { desc = 'Git undo stage hunk' }
                )
                map(
                    'n',
                    '<leader>hR',
                    gs.reset_buffer,
                    { desc = 'Git reset buffer' }
                )
                map(
                    'n',
                    '<leader>hp',
                    gs.preview_hunk,
                    { desc = 'Git preview hunk' }
                )
                map(
                    'n',
                    '<leader>hb',
                    gs.toggle_current_line_blame,
                    { desc = 'Git toggle current line blame' }
                )
                map(
                    'n',
                    '<leader>hd',
                    gs.diffthis,
                    { desc = 'Git diff against index' }
                )
                map('n', '<leader>hD', function()
                    gs.diffthis '~'
                end, {
                    desc = 'Git diff against last commit',
                })

                -- Text object
                map(
                    { 'o', 'x' },
                    'ih',
                    ':<C-U>Gitsigns select_hunk<CR>',
                    { desc = 'Git select hunk' }
                )
            end,
            -- _signs_staged_enable = true,
            -- _signs_staged = {
            --     add = {
            --         text = '┃',
            --     },
            --     change = {
            --         text = '┃',
            --     },
            --     delete = {
            --         text = '▁',
            --     },
            --     topdelete = {
            --         text = '▔',
            --     },
            --     changedelete = {
            --         text = '~',
            --     },
            -- },
        },
    },
    {
        'NeogitOrg/neogit',
        keys = {
            {
                '<leader>g',
                function()
                    require('neogit').open()
                end,
                desc = 'Neogit',
            },
        },
        opts = {
            disable_hint = true,
            signs = {
                section = { '', '' },
                item = { '', '' },
                hunk = { '', '' },
            },
            integrations = {
                diffview = true,
            },
            graph_style = 'kitty',
            status = {
                recent_commit_count = 50,
            },
            process_spinner = true,
        },
        config = function(_, opts)
            local neogit = require 'neogit'
            neogit.setup(opts)

            local augroup =
                vim.api.nvim_create_augroup('NeogitEvents', { clear = true })

            vim.api.nvim_create_autocmd('User', {
                pattern = 'NeogitPushComplete',
                group = augroup,
                callback = neogit.close,
                desc = 'Close Neogit after pushing',
            })

            vim.api.nvim_create_autocmd('User', {
                pattern = {
                    -- 'NeogitStatusRefreshed',
                    'NeogitCommitComplete',
                    'NeogitBranchCheckout',
                    'NeogitBranchReset',
                    'NeogitRebase',
                    'NeogitReset',
                },
                group = augroup,
                callback = function()
                    require('gitsigns').refresh()
                end,
                desc = 'Update gitsigns on Neogit event',
            })

            vim.api.nvim_create_autocmd('User', {
                pattern = {
                    -- 'NeogitStatusRefreshed',
                    'NeogitCommitComplete',
                    'NeogitBranchReset',
                    'NeogitRebase',
                    'NeogitReset',
                },
                group = augroup,
                callback = function()
                    if package.loaded['neo-tree'] then
                        require('neo-tree.sources.git_status').refresh()
                    end
                end,
                desc = 'Update neo-tree on Neogit event',
            })

            vim.api.nvim_create_autocmd('User', {
                pattern = 'GitSignsChanged',
                group = augroup,
                callback = function()
                    neogit.refresh()
                end,
                desc = 'Update Neogit on gitsigns action',
            })
        end,
    },
    {
        'akinsho/git-conflict.nvim',
        event = 'VeryLazy',
        keys = {
            {
                '<leader>co',
                '<Plug>(git-conflict-ours)',
                desc = 'Git conflict pick ours',
            },
            {
                '<leader>ct',
                '<Plug>(git-conflict-theirs)',
                desc = 'Git conflict pick theirs',
            },
            {
                '<leader>cb',
                '<Plug>(git-conflict-both)',
                desc = 'Git conflict pick both',
            },
            {
                '<leader>c0',
                '<Plug>(git-conflict-none)',
                desc = 'Git conflict pick none',
            },
            {
                '[x',
                '<Plug>(git-conflict-prev-conflict)',
                desc = 'Prev conflict',
            },
            {
                ']x',
                '<Plug>(git-conflict-next-conflict)',
                desc = 'Next conflict',
            },
        },
        ---@module 'git-conflict'
        ---@type GitConflictUserConfig
        opts = { default_mappings = false },
    },
    {
        'sindrets/diffview.nvim',
        cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
        ---@module 'diffview.config'
        ---@type DiffviewConfig
        opts = {
            enhanced_diff_hl = true,
            hooks = {
                diff_buf_win_enter = function(bufnr, winid, ctx)
                    -- Turn off cursor line for diffview windows because of bg conflict
                    -- https://github.com/neovim/neovim/issues/9800
                    vim.wo[winid].culopt = 'number'
                end,
            },
            keymaps = {
                view = {
                    {
                        'n',
                        'q',
                        vim.cmd.tabclose,
                        { desc = 'Close diffview' },
                    },
                },
                file_panel = {
                    {
                        'n',
                        'q',
                        vim.cmd.tabclose,
                        { desc = 'Close diffview' },
                    },
                },
            },
        },
    },
    {
        'pwntester/octo.nvim',
        cmd = 'Octo',
        init = function()
            require('which-key').add { { '<leader>o', group = 'Octo' } }
        end,
        keys = {
            {
                '<leader>op',
                function()
                    local pr = require('conf.octo').pr
                    require('coop').spawn(function()
                        if pr.exists() then
                            pr.open()
                        else
                            pr.create()
                        end
                    end)
                end,
                desc = 'Open or create PR for current branch',
            },
            { '<leader>oi', '<cmd>Octo issue list<cr>', desc = 'List issues' },
            {
                '<leader>os',
                '<cmd>Octo search assignee:disrupted<cr>',
                desc = 'Search assigned issues & PRs',
            },
        },
        ---@module 'octo.config'
        ---@type OctoConfig
        opts = {
            picker = 'snacks',
            default_merge_method = 'squash',
            default_delete_branch = true,
            date_format = '%Y %b %d %H:%M',
        },
    },
    {
        'topaxi/pipeline.nvim',
        cmd = 'Pipeline',
        keys = {
            {
                '<leader>ci',
                '<cmd>Pipeline<CR>',
                desc = 'Watch CI pipeline run',
            },
        },
        build = 'make',
        dependencies = { 'nvim-lua/plenary.nvim', 'MunifTanjim/nui.nvim' },
        ---@module 'pipeline.config'
        ---@type pipeline.Config
        opts = {},
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
        'disrupted/github-actions.nvim',
        dir = require('conf.utils').dir '~/dev/github-actions.nvim',
        dev = require('conf.utils').dev '~/dev/github-actions.nvim',
        ft = 'yaml.github',
        ---@module 'github-actions.config'
        ---@type github_actions.Opts
        opts = {},
    },
}
