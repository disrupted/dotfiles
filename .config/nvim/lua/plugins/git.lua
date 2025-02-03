return {
    {
        'lewis6991/gitsigns.nvim',
        event = { 'BufWinEnter', 'BufNewFile' },
        dependencies = { 'purarue/gitsigns-yadm.nvim' },
        opts = function()
            ---@module 'gitsigns.config'
            ---@type Gitsigns.Config
            ---@diagnostic disable: missing-fields
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
                        vim.tbl_contains(
                            ignore_filetypes,
                            vim.bo[bufnr].filetype
                        )
                    then
                        return -- do not attach to buffers of this filetype
                    end
                    if vim.uv.fs_stat '.git' then
                        -- disable YADM if inside Git repo
                        ---@diagnostic disable-next-line: missing-parameter
                        return callback()
                    end
                    require('gitsigns-yadm').yadm_signs(callback)
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
                desc = 'Neogit',
            },
            {
                '<leader>c',
                function()
                    require('neogit').open { 'commit' }
                end,
                desc = 'Commit',
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

            vim.api.nvim_create_autocmd('User', {
                pattern = 'NeogitPushComplete',
                group = vim.api.nvim_create_augroup(
                    'NeogitEvents',
                    { clear = true }
                ),
                callback = neogit.close,
            })
        end,
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
        },
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
                        Snacks.notify.info(url, {
                            title = 'Octo',
                        })
                        local cmd = string.format('Octo %s', url)
                        vim.cmd(cmd)
                    else
                        vim.cmd 'Octo pr list'
                    end
                end,
            },
            { '<leader>oi', '<cmd>Octo issue list<cr>' },
            { '<leader>os', '<cmd>Octo search assignee:disrupted<cr>' },
        },
        ---@module 'octo.config'
        ---@type OctoConfig
        ---@diagnostic disable-next-line: missing-fields
        opts = { date_format = '%Y %b %d %H:%M' },
    },
    {
        'topaxi/pipeline.nvim',
        cmd = 'Pipeline',
        keys = {
            { '<leader>ci', '<cmd>Pipeline<cr>', desc = 'Open pipeline.nvim' },
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
        ---@module 'gitlinker.configs'
        ---@type gitlinker.Options
        opts = {
            router = {
                browse = {
                    -- example: https://github.com/linrongbin16/gitlinker.nvim/blob/9679445c7a24783d27063cd65f525f02def5f128/lua/gitlinker.lua#L3-L4
                    ['^git@github%.com'] = 'https://github.com/'
                        .. '{_A.ORG}/'
                        .. '{_A.REPO}/blob/'
                        .. '{_A.REV}/'
                        .. '{_A.FILE}?plain=1' -- '?plain=1'
                        .. '#L{_A.LSTART}'
                        .. '{(_A.LEND > _A.LSTART and (\'-L\' .. _A.LEND) or \'\')}',
                },
            },
        },
    },
    {
        'disrupted/github-actions.nvim',
        dir = require('conf.utils').dir '~/dev/github-actions.nvim',
        dev = require('conf.utils').dev '~/dev/github-actions.nvim',
        ft = 'yaml.github',
        ---@module 'github-actions.config'
        ---@type github_actions.Opts
        opts = {
            token_provider = function()
                local cb_to_co = require('coop.coroutine-utils').cb_to_co

                local co = cb_to_co(function(cb)
                    require('op').get_secret_async(
                        'jjo3wbo4qje4olvisp6lcqci3u',
                        'uutpi5dmo2j3let5hvwjtbnf4u',
                        cb
                    )
                end)
                return co()
            end,
        },
    },
}
