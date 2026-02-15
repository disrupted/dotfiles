local icons = require 'conf.icons'
---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'lewis6991/gitsigns.nvim',
        event = { 'BufWinEnter', 'BufNewFile' },
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

                -- Navigation
                map('n', ']g', function()
                    if vim.wo.diff then
                        vim.cmd.normal { ']g', bang = true }
                    else
                        gs.nav_hunk('next', { target = 'all' })
                    end
                end, { desc = 'Next Git hunk' })
                map('n', '[g', function()
                    if vim.wo.diff then
                        vim.cmd.normal { '[g', bang = true }
                    else
                        gs.nav_hunk('prev', { target = 'all' })
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
            end,
        },
    },
    {
        'NeogitOrg/neogit',
        keys = {
            {
                '<Leader>gg',
                function()
                    require('neogit').open { kind = 'tab' }
                    vim.cmd.tabmove()
                end,
                desc = 'Neogit',
            },
            {
                '<tab>',
                function()
                    require('neogit').open { kind = 'tab' }
                    vim.cmd.tabmove()
                end,
                desc = 'Neogit',
            },
        },
        ---@module 'neogit.config'
        ---@type NeogitConfig
        opts = {
            disable_hint = true,
            disable_signs = true,
            integrations = {
                codediff = true,
                snacks = true,
            },
            diff_viewer = 'codediff',
            graph_style = 'kitty',
            status = {
                recent_commit_count = 50,
            },
            process_spinner = true,
        },
        ---@param opts NeogitConfig
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

            vim.api.nvim_create_autocmd({ 'BufEnter' }, {
                pattern = 'NeogitStatus',
                group = augroup,
                callback = neogit.refresh,
                desc = 'Update Neogit status on enter',
            })

            -- vim.api.nvim_create_autocmd('User', {
            --     pattern = 'NeogitStatusRefreshed',
            --     command = 'checktime',
            --     desc = 'Reload buffer on Neogit status refresh',
            -- })

            vim.api.nvim_create_autocmd('User', {
                pattern = {
                    'NeogitCommitComplete',
                    'NeogitBranchCheckout',
                    'NeogitBranchReset',
                    'NeogitRebase',
                    'NeogitReset',
                },
                group = augroup,
                callback = neogit.refresh,
                desc = 'Refresh Neogit',
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

            -- vim.api.nvim_create_autocmd('User', {
            --     pattern = 'GitSignsChanged',
            --     group = augroup,
            --     callback = neogit.refresh,
            --     desc = 'Update Neogit on gitsigns action',
            -- })
        end,
    },
    {
        'barrettruth/diffs.nvim',
        enabled = false,
        event = { 'BufWinEnter', 'BufNewFile' },
        -- ft = {
        --     'git',
        --     'gitcommit',
        --     'diff',
        --     'NeogitStatus',
        --     'NeogitCommitView',
        --     'NeogitDiffView',
        -- },
        keys = {
            {
                '<Leader>gxo',
                '<Plug>(diffs-conflict-ours)',
                desc = 'Pick ours',
            },
            {
                '<Leader>gxt',
                '<Plug>(diffs-conflict-theirs)',
                desc = 'Pick theirs',
            },
            {
                '<Leader>gxa',
                '<Plug>(diffs-conflict-both)',
                desc = 'Pick all',
            },
            {
                '<Leader>gx0',
                '<Plug>(diffs-conflict-none)',
                desc = 'Pick none',
            },
            {
                '[x',
                '<Plug>(diffs-conflict-prev)',
                desc = 'Prev conflict',
            },
            {
                ']x',
                '<Plug>(diffs-conflict-next)',
                desc = 'Next conflict',
            },
        },
        init = function()
            require('which-key').add { { '<Leader>gx', group = 'Conflict' } }

            ---@type diffs.Config
            vim.g.diffs = {
                hide_prefix = true,
                neogit = true,
                extra_filetypes = { 'diff' },
                conflict = {
                    enabled = true,
                    disable_diagnostics = true,
                    show_virtual_text = true,
                    show_actions = false,
                    priority = 200,
                    keymaps = {
                        ours = '<Leader>gxo',
                        theirs = '<Leader>gxt',
                        both = '<Leader>gxa',
                        none = '<Leader>gx0',
                        next = ']x',
                        prev = '[x',
                    },
                },
                highlights = {
                    background = true,
                    gutter = false,
                    -- blend_alpha = 0.2,
                    intra = {
                        enabled = true,
                        algorithm = 'vscode',
                        -- max_lines = 500,
                    },
                },
            }
        end,
        config = function()
            vim.api.nvim_create_autocmd('User', {
                pattern = 'DiffsConflictResolved',
                callback = function()
                    Snacks.notify 'all conflicts resolved!'
                end,
            })
        end,
    },
    {
        'sindrets/diffview.nvim',
        enabled = false, -- Disabled in favor of codediff.nvim
        cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
        init = function()
            require('which-key').add {
                {
                    '<Leader>gd',
                    group = 'Diffview',
                    icon = icons.git.diff,
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
                file_panel = {
                    win_config = {
                        win_opts = { statuscolumn = '', signcolumn = 'auto' },
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
        'esmuellert/codediff.nvim',
        dependencies = { 'MunifTanjim/nui.nvim' },
        cmd = 'CodeDiff',
        init = function()
            require('which-key').add {
                {
                    '<Leader>gd',
                    group = 'Codediff',
                    icon = icons.git.diff,
                },
            }
        end,
        keys = {
            {
                '<Leader>gdr',
                function()
                    vim.ui.input(
                        { prompt = 'Codediff Revision' },
                        function(revision)
                            if revision and revision ~= '' then
                                vim.cmd('CodeDiff ' .. revision)
                            else
                                vim.cmd 'CodeDiff' -- No revision = git status
                            end
                        end
                    )
                end,
                desc = 'Revision',
            },
            {
                '<Leader>gdf',
                '<cmd>CodeDiff history %<CR>',
                desc = 'File history',
            },
            {
                '<Leader>gdb',
                function()
                    vim.cmd 'CodeDiff history origin/HEAD..HEAD'
                    -- require('gitsigns').change_base('origin/HEAD', true)
                end,
                desc = 'Review branch changes',
            },
        },
        config = function()
            require('codediff').setup {
                highlights = {
                    line_insert = 'DiffAdd',
                    line_delete = 'DiffDelete',
                    char_brightness = nil, -- Auto-detect based on background
                },
                diff = {
                    disable_inlay_hints = true,
                    original_position = 'left',
                    conflict_ours_position = 'right',
                },
                explorer = {
                    position = 'left',
                    width = 40,
                    view_mode = 'list',
                    initial_focus = 'explorer',
                    indent_markers = true,
                },
                history = {
                    position = 'bottom',
                    height = 15,
                    initial_focus = 'history',
                    view_mode = 'list',
                },
                keymaps = {
                    view = {
                        quit = 'q',
                        toggle_explorer = '<C-e>',
                        next_hunk = ']c',
                        prev_hunk = '[c',
                        next_file = ']q',
                        prev_file = '[q',
                        diff_get = 'do',
                        diff_put = 'dp',
                        toggle_stage = 's',
                    },
                    explorer = {
                        select = '<CR>',
                        hover = 'K',
                        refresh = 'R',
                        toggle_view_mode = 'i',
                        stage_all = 'S',
                        unstage_all = 'U',
                        restore = 'x',
                    },
                    history = {
                        select = '<CR>',
                        toggle_view_mode = 'i',
                    },
                    conflict = {
                        accept_incoming = '<LocalLeader>xt', -- theirs
                        accept_current = '<LocalLeader>xo', -- ours
                        accept_both = '<LocalLeader>xa', -- all
                        discard = '<LocalLeader>xb', -- discard both
                        next_conflict = ']x',
                        prev_conflict = '[x',
                        diffget_incoming = '2do',
                        diffget_current = '3do',
                    },
                },
            }
        end,
    },
    {
        'pwntester/octo.nvim',
        cmd = 'Octo',
        init = function()
            require('which-key').add {
                { '<Leader>go', group = 'Octo', icon = icons.git.github },
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
                            if not require('gh').pr.exists() then
                                pr.form_create()
                            else
                                pr.open()
                            end
                        end)
                    end,
                    desc = 'View or create PR',
                    icon = icons.git.pull_request,
                },
                {
                    '<Leader>goi',
                    '<cmd>Octo issue list<cr>',
                    desc = 'List issues',
                    icon = icons.git.issue,
                },
                {
                    '<Leader>gor',
                    '<cmd>Octo review<cr>',
                    desc = 'Review PR',
                    icon = icons.git.review,
                },
                {
                    '<Leader>gos',
                    '<cmd>Octo search assignee:disrupted<cr>', -- FIXME: not implemented for Snacks picker yet
                    desc = 'Search assigned issues & PRs',
                    icon = '',
                },
            }
        end,
        ---@module 'octo.config'
        ---@type OctoConfig
        opts = {
            picker = 'snacks',
            default_merge_method = 'squash',
            default_delete_branch = true,
            date_format = '%Y %b %d %H:%M',
            mappings = {
                issue = {
                    close_issue = { desc = 'Close' },
                    reopen_issue = { desc = 'Reopen' },
                },
                pull_request = {
                    resolve_thread = {
                        lhs = '<LocalLeader>cr',
                        desc = 'Resolve thread',
                    },
                    unresolve_thread = {
                        lhs = '<LocalLeader>cu',
                        desc = 'Unresolve thread',
                    },
                    show_pr_diff = { lhs = '<LocalLeader>pD' },
                    -- wrong naming
                    close_issue = { desc = 'Close' },
                    reopen_issue = { desc = 'Reopen' },
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
                    { 'q', vim.cmd.tabclose, desc = 'Close Octo' },
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
                    {
                        '<LocalLeader>i',
                        group = 'Issue',
                        icon = icons.git.issue,
                    },
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
                    {
                        '<LocalLeader>gi',
                        desc = 'Issue',
                        icon = icons.git.issue,
                    },
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
                    {
                        '<LocalLeader>p',
                        group = 'PR',
                        icon = icons.git.pull_request,
                    },
                    {
                        '<LocalLeader>pc',
                        desc = 'Commits',
                        icon = icons.git.commit,
                    },
                    { '<LocalLeader>pD', desc = 'Diff', icon = icons.git.diff }, -- I prefer diffview
                    {
                        '<LocalLeader>pf',
                        desc = 'Files',
                        icon = icons.documents.file,
                    },
                    {
                        '<LocalLeader>po',
                        desc = 'Checkout',
                        icon = icons.git.checkout,
                    },
                    {
                        '<LocalLeader>pr',
                        function()
                            vim.cmd { cmd = 'Octo', args = { 'pr', 'ready' } }
                        end,
                        desc = 'Ready for review',
                        icon = '',
                    },
                    {
                        '<LocalLeader>pd',
                        function()
                            vim.cmd { cmd = 'Octo', args = { 'pr', 'draft' } }
                        end,
                        desc = 'Convert back to draft',
                        icon = '',
                    },
                    {
                        '<LocalLeader>pu',
                        function()
                            vim.cmd { cmd = 'Octo', args = { 'pr', 'url' } }
                        end,
                        desc = 'Copy URL',
                        icon = '󰌹',
                    },
                    {
                        '<LocalLeader>pb',
                        function()
                            vim.cmd { cmd = 'Octo', args = { 'pr', 'browser' } }
                        end,
                        desc = 'Open in browser',
                        icon = '',
                    },
                    {
                        '<LocalLeader>ps',
                        desc = 'Squash',
                        icon = icons.git.squash,
                    },
                    { '<LocalLeader>psm', desc = 'Squash & merge' },
                    {
                        '<LocalLeader>v',
                        group = 'Review',
                        icon = icons.git.review,
                    },
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
            local function attach_issue(buf)
                wk.add {
                    buffer = buf,
                    {
                        '<LocalLeader>iu',
                        function()
                            vim.cmd { cmd = 'Octo', args = { 'issue', 'url' } }
                        end,
                        desc = 'Copy URL',
                        icon = '󰌹',
                    },
                    {
                        '<LocalLeader>ib',
                        function()
                            vim.cmd {
                                cmd = 'Octo',
                                args = { 'issue', 'browser' },
                            }
                        end,
                        desc = 'Open in browser',
                        icon = '',
                    },
                }
            end
            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'octo',
                callback = function(args)
                    attach_octo(args.buf)
                    if args.file:match '^octo://.*/pull/' then
                        attach_pull_request(args.buf)
                    elseif args.file:match '^octo://.*/issue/' then
                        attach_issue(args.buf)
                    end
                end,
            })

            -- shared keymaps for review_diff and file_panel
            local function attach_shared_review_diff_file_panel(buf)
                wk.add {
                    buffer = buf,
                    {
                        '<LocalLeader>v',
                        desc = 'Review',
                        icon = icons.git.review,
                    },
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
        opts = {
            split = {
                buf_options = {
                    filetype = 'pipeline',
                },
            },
        },
    },
    {
        'harrisoncramer/gitlab.nvim',
        -- enabled = false, -- incompatible with codediff.nvim https://github.com/harrisoncramer/gitlab.nvim/issues/517
        lazy = true,
        dependencies = {
            'MunifTanjim/nui.nvim',
            'nvim-lua/plenary.nvim',
            'sindrets/diffview.nvim',
        },
        init = function()
            require('which-key').add {
                { '<Leader>ga', group = 'GitLab', icon = icons.git.gitlab },
                {
                    '<Leader>gap',
                    function()
                        require('coop').spawn(function()
                            local git = require('git').async
                            local remote_url = git.remote_url()
                            if
                                require('git').match_remote_type(remote_url)
                                ~= 'gitlab'
                            then
                                Snacks.notify.error 'Only GitLab supported'
                                return
                            end
                            local branch = git.current_branch()
                            if branch == '' then
                                Snacks.notify.error 'Current ref is not a valid branch'
                                return
                            end
                            if branch == git.default_branch() then
                                Snacks.notify.error 'MR is not possible on default branch'
                                return
                            end

                            local mr = require('glab').mr
                            if not mr.exists() then
                                require('conf.gitlab').mr.form_create()
                            else
                                require('conf.gitlab').mr.open()
                            end
                        end)
                    end,
                    desc = 'View or create MR',
                    icon = icons.git.pull_request,
                },
                {
                    '<Leader>gar',
                    function()
                        require('gitlab').choose_merge_request()
                    end,
                    desc = 'Review MR',
                    icon = icons.git.review,
                },
            }
        end,
        build = function()
            require('gitlab.server').build(true)
        end,
        opts = {
            create_mr = {
                delete_branch = true,
                squash = true,
            },
        },
    },
    {
        'Hdoc1509/gh-actions.nvim',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        config = function()
            require('gh-actions.tree-sitter').setup()
            require('nvim-treesitter').install 'gh_actions_expressions'
        end,
    },
    {
        'disrupted/github-actions.nvim',
        dir = require('conf.utils').dir '~/dev/github-actions.nvim',
        dev = require('conf.utils').dev '~/dev/github-actions.nvim',
        ft = 'yaml.github',
        ---@module 'github-actions.config'
        ---@type github_actions.Opts
        opts = {
            lsp = {
                cmd = {
                    'bunx',
                    '--bun',
                    'gh-actions-language-server',
                    '--stdio',
                },
            },
        },
    },
}
