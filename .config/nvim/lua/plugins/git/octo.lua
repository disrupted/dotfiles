local icons = require('conf.icons')

---@type LazeSpec
return {
    'pwntester/octo.nvim',
    main = 'octo',
    module = 'octo',
    cmd = 'Octo',
    init = function()
        require('which-key').add({
            { '<Leader>go', group = 'Octo', icon = icons.git.github },
            {
                '<Leader>gop',
                function()
                    local task = vim.async.run(function()
                        local git = require('git').async
                        local remote_url = git.remote_url()
                        if require('git').match_remote_type(remote_url) ~= 'github' then
                            Snacks.notify.error('Octo only supports GitHub')
                            return
                        end
                        local branch = git.current_branch()
                        if branch == '' then
                            Snacks.notify.error('Current ref is not a valid branch')
                            return
                        end
                        if branch == git.default_branch() then
                            Snacks.notify.error('PR is not possible on default branch')
                            return
                        end
                        local unpushed = git.unpushed_commits()
                        if unpushed == nil then
                            Snacks.notify.warn(
                                'Branch has no upstream, push it with -u first',
                                { title = 'GitHub' }
                            )
                        elseif unpushed > 0 then
                            Snacks.notify.warn(
                                ('%d unpushed commit(s)'):format(unpushed),
                                { title = 'GitHub' }
                            )
                        end
                        local pr = require('conf.octo').pr
                        local existing_pr = require('gh').pr.json({ 'number' })
                        if not existing_pr then
                            local unpushed = git.unpushed_commits()
                            if unpushed == nil then
                                Snacks.notify.error(
                                    'Branch has no upstream, push it with -u first',
                                    { title = 'GitHub' }
                                )
                                return
                            elseif unpushed > 0 then
                                Snacks.notify.warn(
                                    ('%d unpushed commit(s)'):format(unpushed),
                                    { title = 'GitHub' }
                                )
                            end
                            pr.form_create()
                        else
                            pr.open({
                                number = existing_pr.number,
                                octo = true,
                                browser = false,
                            })
                        end
                    end)
                    task:raise_on_error()
                end,
                desc = 'View or create PR',
                icon = icons.git.pull_request,
            },
            {
                '<Leader>gor',
                '<cmd>Octo review<cr>',
                desc = 'Review PR',
                icon = icons.git.review,
            },
            {
                '<Leader>gos',
                '<cmd>Octo search assignee:disrupted<cr>',
                desc = 'Search assigned issues & PRs',
                icon = icons.misc.search,
            },
        })

        -- FIXME: register in the Snacks gh picker actions menu
        -- local gh_actions = require 'snacks.gh.actions'
        -- ---@type snacks.gh.Action
        -- gh_actions.actions.gh_open_octo = {
        --     title = 'Open {type} #{number} in Octo',
        --     icon = icons.git.github .. ' ',
        --     action = function(item, ctx)
        --         if ctx.picker then
        --             ctx.picker:close()
        --         end
        --         local kind = item.type == 'pr' and 'pull' or 'issue'
        --         require 'octo'
        --         vim.cmd {
        --             cmd = 'edit',
        --             args = {
        --                 string.format(
        --                     'octo://%s/%s/%s',
        --                     item.repo,
        --                     kind,
        --                     item.number
        --                 ),
        --             },
        --         }
        --     end,
        -- }
    end,
    config = function()
        ---@module 'octo.config'
        ---@type OctoConfig
        local opts = {
            picker = 'snacks',
            -- enable_builtin = true,
            -- picker_config = {
            --     snacks = {
            --         actions = {
            --             issues = {
            --                 {
            --                     name = 'confirm',
            --                     fn = open_in_tab,
            --                     lhs = '<CR>',
            --                     desc = 'Open in tab',
            --                     mode = { 'n', 'i' },
            --                 },
            --             },
            --             pull_requests = {
            --                 {
            --                     name = 'confirm',
            --                     fn = open_in_tab,
            --                     lhs = '<CR>',
            --                     desc = 'Open in tab',
            --                     mode = { 'n', 'i' },
            --                 },
            --             },
            --             notifications = {
            --                 {
            --                     name = 'confirm',
            --                     fn = open_in_tab,
            --                     lhs = '<CR>',
            --                     desc = 'Open in tab',
            --                     mode = { 'n', 'i' },
            --                 },
            --             },
            --             search = {
            --                 {
            --                     name = 'confirm',
            --                     fn = open_in_tab,
            --                     lhs = '<CR>',
            --                     desc = 'Open in tab',
            --                     mode = { 'n', 'i' },
            --                 },
            --             },
            --         },
            --     },
            -- },
            default_merge_method = 'squash',
            default_delete_branch = true,
            date_format = '%Y %b %d %H:%M',
            poll = {
                enabled = true,
            },
            mappings = {
                issue = {
                    close_issue = { desc = 'Close' },
                    reopen_issue = { desc = 'Reopen' },
                },
                pull_request = {
                    review = {
                        lhs = '<LocalLeader>vr',
                        desc = 'Review',
                    },
                    review_start = { lhs = '' },
                    review_resume = { lhs = '' },
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
                    merge_pr_queue = { lhs = '' },
                    squash_and_merge_queue = { lhs = '' },
                    rebase_and_merge_queue = { lhs = '' },
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
        }
        require('octo').setup(opts)
        vim.treesitter.language.register('markdown', 'octo')

        local wk = require('which-key')
        -- shared keymaps for pull_request & issue
        local function attach_octo(buf)
            wk.add({
                buffer = buf,
                { 'q', vim.cmd.tabclose, desc = 'Close Octo' },
                {
                    '<LocalLeader>a',
                    group = 'Assignee',
                    icon = icons.misc.user,
                },
                {
                    '<LocalLeader>aa',
                    desc = 'Add',
                    icon = icons.misc.user_plus,
                },
                {
                    '<LocalLeader>ad',
                    desc = 'Remove',
                    icon = icons.misc.user_minus,
                },
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
            })
        end
        local function attach_pull_request(buf)
            wk.add({
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
                        vim.cmd({ cmd = 'Octo', args = { 'pr', 'ready' } })
                    end,
                    desc = 'Ready for review',
                    icon = '',
                },
                {
                    '<LocalLeader>pd',
                    function()
                        vim.cmd({ cmd = 'Octo', args = { 'pr', 'draft' } })
                    end,
                    desc = 'Convert back to draft',
                    icon = '',
                },
                {
                    '<LocalLeader>pu',
                    function()
                        vim.cmd({ cmd = 'Octo', args = { 'pr', 'url' } })
                    end,
                    desc = 'Copy URL',
                    icon = '󰌹',
                },
                {
                    '<LocalLeader>pb',
                    function()
                        vim.cmd({ cmd = 'Octo', args = { 'pr', 'browser' } })
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
                { '<LocalLeader>vr', desc = 'Review' },
                {
                    '<LocalLeader>t',
                    group = 'Toggle',
                },
                {
                    '<LocalLeader>tc',
                    desc = 'Checks',
                    icon = {
                        icon = icons.test.passed,
                        hl = 'DiagnosticInfo',
                    },
                },
            })
        end
        local function attach_issue(buf)
            wk.add({
                buffer = buf,
                {
                    '<LocalLeader>iu',
                    function()
                        vim.cmd({ cmd = 'Octo', args = { 'issue', 'url' } })
                    end,
                    desc = 'Copy URL',
                    icon = '󰌹',
                },
                {
                    '<LocalLeader>ib',
                    function()
                        vim.cmd({
                            cmd = 'Octo',
                            args = { 'issue', 'browser' },
                        })
                    end,
                    desc = 'Open in browser',
                    icon = '',
                },
            })
        end
        vim.api.nvim_create_autocmd('FileType', {
            pattern = 'octo',
            callback = function(args)
                attach_octo(args.buf)
                if args.file:match('^octo://.*/pull/') then
                    attach_pull_request(args.buf)
                elseif args.file:match('^octo://.*/issue/') then
                    attach_issue(args.buf)
                end
            end,
        })

        -- shared keymaps for review_diff and file_panel
        local function attach_shared_review_diff_file_panel(buf)
            wk.add({
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
            })
        end
        vim.api.nvim_create_autocmd('FileType', {
            pattern = 'octo_panel',
            callback = function(args)
                attach_shared_review_diff_file_panel(args.buf)
            end,
        })

        local function attach_review_diff(buf)
            wk.add({
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
            })
        end
        vim.api.nvim_create_autocmd('BufEnter', {
            pattern = 'octo://*/review/*', -- review buffer
            callback = function(args)
                attach_review_diff(args.buf)
                attach_shared_review_diff_file_panel(args.buf)
            end,
        })
    end,
}
