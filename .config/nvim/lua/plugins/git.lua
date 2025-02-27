---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'lewis6991/gitsigns.nvim',
        event = { 'BufWinEnter', 'BufNewFile' },
        dependencies = { 'purarue/gitsigns-yadm.nvim' },
        init = function()
            require('which-key').add {
                {
                    '<Leader>g',
                    mode = { 'n', 'v' },
                    group = 'Git',
                    icon = '',
                },
            }
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
                map(
                    'n',
                    ']g',
                    vim.schedule_wrap(gs.next_hunk),
                    { desc = 'Next Git hunk' }
                )
                map(
                    'n',
                    '[g',
                    vim.schedule_wrap(gs.prev_hunk),
                    { desc = 'Prev Git hunk' }
                )
                map('n', '<Leader>gs', gs.stage_hunk, { desc = 'Stage hunk' })
                map('v', '<Leader>gs', function()
                    gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
                end, { desc = 'Stage hunk' })
                map('n', '<Leader>gr', gs.reset_hunk, { desc = 'Reset hunk' })
                map('v', '<Leader>gr', function()
                    gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
                end, { desc = 'Reset hunk' })
                map(
                    'n',
                    '<Leader>gS',
                    gs.stage_buffer,
                    { desc = 'Stage buffer' }
                )
                map(
                    'n',
                    '<Leader>gR',
                    gs.reset_buffer,
                    { desc = 'Reset buffer' }
                )
                map(
                    'n',
                    '<Leader>gp',
                    gs.preview_hunk,
                    { desc = 'Preview hunk' }
                )
                map(
                    'n',
                    '<Leader>gb',
                    gs.toggle_current_line_blame,
                    { desc = 'Blame' }
                )
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

                -- lazy-load git-conflict
                require 'git-conflict'
            end,
        },
    },
    {
        'NeogitOrg/neogit',
        keys = {
            {
                '<Leader>gg',
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
        lazy = true, -- lazy-loaded on gitsigns attach
        init = function()
            require('which-key').add { { '<Leader>gx', group = 'Conflict' } }
        end,
        keys = {
            {
                '<Leader>gxo',
                '<Plug>(git-conflict-ours)',
                desc = 'Pick ours',
            },
            {
                '<Leader>gxt',
                '<Plug>(git-conflict-theirs)',
                desc = 'Pick theirs',
            },
            {
                '<Leader>gxb',
                '<Plug>(git-conflict-both)',
                desc = 'Pick both',
            },
            {
                '<Leader>gx0',
                '<Plug>(git-conflict-none)',
                desc = 'Pick none',
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
        init = function()
            require('which-key').add {
                {
                    '<Leader>gd',
                    group = 'Diffview',
                    icon = '',
                },
            }
        end,
        keys = {
            {
                '<Leader>gdr',
                function()
                    vim.ui.input(
                        { prompt = 'Diffview Revision' },
                        function(revision)
                            local cmd = 'DiffviewOpen'
                            if revision then
                                cmd = cmd .. ' ' .. revision
                            end
                            vim.cmd(cmd .. ' -- .')
                        end
                    )
                end,
                desc = 'Revision',
            },
            {
                '<Leader>gdf',
                '<cmd>DiffviewFileHistory %<CR>',
                desc = 'File history',
            },
            {
                '<Leader>gdb',
                function()
                    vim.cmd.DiffviewOpen 'origin/HEAD...HEAD -- .'
                    require('gitsigns').change_base('origin/HEAD', true)
                end,
                desc = 'Review branch changes',
            },
        },
        opts = function()
            ---@module 'diffview.config'
            ---@type DiffviewConfig
            return {
                enhanced_diff_hl = true,
                default_args = {
                    DiffviewOpen = { '--untracked-files=no', '--imply-local' },
                    DiffviewFileHistory = { '--base=LOCAL', '--no-merges' },
                },
                view = {
                    default = { winbar_info = true },
                    file_history = { winbar_info = true },
                    merge_tool = {
                        -- layout = 'diff4_mixed',
                        disable_diagnostics = true,
                        winbar_info = true,
                    },
                },
                hooks = {
                    diff_buf_win_enter = function(bufnr, winid, ctx)
                        -- Turn off cursor line for diffview windows because of bg conflict
                        -- https://github.com/neovim/neovim/issues/9800
                        vim.wo[winid].cursorlineopt = 'number'
                        vim.wo[winid].wrap = false
                        vim.wo[winid].statuscolumn = ''
                    end,
                },
                keymaps = require('conf.diffview').keymaps,
            }
        end,
    },
    {
        'pwntester/octo.nvim',
        cmd = 'Octo',
        init = function()
            require('which-key').add {
                { '<Leader>go', group = 'Octo', icon = '' },
                { '<Leader>gop', icon = '' },
                { '<Leader>goi', icon = '' },
                { '<Leader>gor', icon = '' },
                { '<Leader>gos', icon = '' },
            }
        end,
        keys = {
            {
                '<Leader>gop',
                function()
                    require('coop').spawn(function()
                        local git = require('git').async
                        local remote_url = git.remote_url()
                        if
                            require('git').match_remote_type(remote_url)
                            ~= 'github'
                        then
                            Snacks.notify.error 'Octo only supports GitHub'
                            return
                        end
                        local branch = git.current_branch()
                        if branch == '' then
                            Snacks.notify.error 'Current ref is not a valid branch'
                            return
                        end
                        if branch == git.default_branch() then
                            Snacks.notify.error 'PR is not possible on default branch'
                            return
                        end
                        local pr = require('conf.octo').pr
                        if not pr.exists() then
                            if not pr.create() then
                                return
                            end
                            Snacks.notify 'created PR'
                            require('coop.uv-utils').sleep(2000)
                        end
                        pr.open()
                    end)
                end,
                desc = 'View or create PR',
            },
            { '<Leader>goi', '<cmd>Octo issue list<cr>', desc = 'List issues' },
            { '<Leader>gor', '<cmd>Octo review<cr>', desc = 'Review PR' },
            {
                '<Leader>gos',
                '<cmd>Octo search assignee:disrupted<cr>', -- TODO: not implemented yet
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
            mappings = {
                pull_request = {
                    resolve_thread = {
                        lhs = '<LocalLeader>cu',
                        desc = 'Unresolve thread',
                    },
                    unresolve_thread = {
                        lhs = '<LocalLeader>cr',
                        desc = 'Unresolve thread',
                    },
                    -- wrong naming
                    close_issue = { lhs = '', desc = 'close PR' },
                    reopen_issue = { lhs = '', desc = 'reopen PR' },
                    -- always squash & merge
                    merge_pr = { lhs = '' },
                    rebase_and_merge_pr = { lhs = '' },
                },
                review_diff = {
                    next_thread = {
                        lhs = ']t', -- TODO: use same ]c mapping as pull_request?
                        desc = 'Next thread',
                        remap = true,
                    },
                    prev_thread = {
                        lhs = '[t',
                        desc = 'Prev thread',
                        remap = true,
                    },
                    select_next_entry = {
                        lhs = ']q',
                        desc = 'Next file',
                        remap = true,
                    },
                    select_prev_entry = {
                        lhs = '[q',
                        desc = 'Prev file',
                        remap = true,
                    },
                    focus_files = {
                        lhs = '<C-e>',
                        desc = 'Focus file panel',
                        remap = true,
                    },
                    toggle_files = { lhs = '' },
                },
                file_panel = {
                    focus_files = { lhs = '' },
                    toggle_files = {
                        lhs = '<C-e>',
                        desc = 'Toggle files panel',
                        remap = true,
                    },
                },
                submit_win = {
                    approve_review = {
                        lhs = '<C-a>',
                        desc = 'Approve',
                        mode = { 'n', 'i' },
                    },
                    comment_review = {
                        lhs = '<C-m>',
                        desc = 'Comment',
                        mode = { 'n', 'i' },
                    },
                    request_changes = {
                        lhs = '<C-r>',
                        desc = 'Request changes',
                        mode = { 'n', 'i' },
                    },
                    close_review_tab = {
                        lhs = '<C-c>',
                        desc = 'Close',
                        mode = { 'n', 'i' },
                    },
                },
            },
        },
        config = function(_, opts)
            require('octo').setup(opts)
            vim.treesitter.language.register('markdown', 'octo')

            local wk = require 'which-key'
            -- shared keymaps for pull_request & issue
            local function attach_octo(buf)
                wk.add {
                    buffer = buf,
                    { '<LocalLeader>a', group = 'Assignee', icon = '' },
                    { '<LocalLeader>aa', desc = 'Add', icon = '' },
                    { '<LocalLeader>ad', desc = 'Remove', icon = '' },
                    {
                        '<LocalLeader>c',
                        group = 'Comment/Thread', -- TODO: makes sense to split?
                        icon = '',
                    },
                    { '<LocalLeader>ca', desc = 'Add', icon = '󰆃' },
                    { '<LocalLeader>cd', desc = 'Delete', icon = '󱗠' },
                    { '<LocalLeader>l', group = 'Label', icon = '󰓹' },
                    { '<LocalLeader>la', desc = 'Add', icon = '󰜢' },
                    { '<LocalLeader>ld', desc = 'Remove', icon = '󰤐' },
                    { '<LocalLeader>lc', desc = 'Create', icon = '󰜢' },
                    { '<LocalLeader>i', group = 'Issue', icon = '' },
                    { '<LocalLeader>il', group = 'List open issues' },
                    { '<LocalLeader>r', group = 'React', icon = '👀' },
                    { '<LocalLeader>rp', desc = '', icon = '🎉' },
                    { '<LocalLeader>rh', desc = '', icon = '💛' }, -- FIXME: ❤️ is broken
                    { '<LocalLeader>re', desc = '', icon = '👀' },
                    { '<LocalLeader>r+', desc = '', icon = '👍' },
                    { '<LocalLeader>r-', desc = '', icon = '👎' },
                    { '<LocalLeader>rr', desc = '', icon = '🚀' },
                    { '<LocalLeader>rl', desc = '', icon = '😄' },
                    { '<LocalLeader>rc', desc = '', icon = '😕' },
                    { '<LocalLeader>g', desc = 'Go to', icon = '' },
                    { '<LocalLeader>gi', desc = 'Issue', icon = '' },
                }
            end
            local function attach_pull_request(buf)
                wk.add {
                    buffer = buf,
                    {
                        '<LocalLeader>cr',
                        desc = 'Resolve thread',
                        icon = '',
                    },
                    {
                        '<LocalLeader>cu',
                        desc = 'Unresolve thread',
                        icon = '',
                    },
                    { '<LocalLeader>p', group = 'PR', icon = '' },
                    { '<LocalLeader>pc', desc = 'Commits', icon = '󰜘' },
                    { '<LocalLeader>pd', desc = 'Diff', icon = '' },
                    { '<LocalLeader>pf', desc = 'Files', icon = '󰈙' },
                    { '<LocalLeader>po', desc = 'Checkout', icon = '󰇚' },
                    { '<LocalLeader>ps', desc = 'Squash', icon = '󰃸' },
                    { '<LocalLeader>psm', desc = 'Squash & merge' },
                    { '<LocalLeader>v', group = 'Review', icon = '' },
                    { '<LocalLeader>va', desc = 'Add reviewer', icon = '' },
                    {
                        '<LocalLeader>vd',
                        desc = 'Remove reviewer request',
                        icon = '',
                    },
                    {
                        '<LocalLeader>vr',
                        desc = 'Resume pending review',
                        icon = '󰔟',
                    },
                    { '<LocalLeader>vs', desc = 'Start review' },
                }
            end
            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'octo',
                callback = function(args)
                    attach_octo(args.buf)
                    if args.file:match '^octo://.*/pull/' then
                        attach_pull_request(args.buf)
                    end
                end,
            })

            -- shared keymaps for review_diff and file_panel
            local function attach_shared_review_diff_file_panel(buf)
                wk.add {
                    buffer = buf,
                    { '<LocalLeader>v', desc = 'Review', icon = '' },
                    { '<LocalLeader>vs', desc = 'Submit', icon = '' },
                    { '<LocalLeader>vd', desc = 'Discard', icon = '' },
                    {
                        '<LocalLeader><Space>',
                        desc = 'Mark viewed',
                        icon = '',
                    },
                }
            end
            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'octo_panel',
                callback = function(args)
                    attach_shared_review_diff_file_panel(args.buf)
                end,
            })

            local function attach_review_diff(buf)
                wk.add {
                    buffer = buf,
                    { '<LocalLeader>c', desc = 'Comment', icon = '' },
                    {
                        '<LocalLeader>ca',
                        desc = 'Add',
                        icon = '󰆃',
                        mode = { 'n', 'x' },
                    },
                    { '<LocalLeader>cd', desc = 'Delete', icon = '󱗠' },
                    { '<LocalLeader>s', desc = 'Suggestion', icon = '󰦒' },
                    { '<LocalLeader>sa', desc = 'Add', mode = { 'n', 'x' } },
                    {
                        '<LocalLeader>q',
                        '<cmd>Octo review close<CR>',
                        desc = 'Close review',
                        icon = '',
                    },
                }
            end
            vim.api.nvim_create_autocmd('BufEnter', {
                pattern = 'octo://*/review/*', -- review buffer
                callback = function(args)
                    attach_review_diff(args.buf)
                    attach_shared_review_diff_file_panel(args.buf)
                end,
            })
        end,
    },
    {
        'topaxi/pipeline.nvim',
        cmd = 'Pipeline',
        init = function()
            require('which-key').add { { '<Leader>gc', group = 'CI' } }
        end,
        keys = {
            {
                '<Leader>gci',
                '<cmd>Pipeline<CR>',
                desc = 'Watch pipeline run',
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
