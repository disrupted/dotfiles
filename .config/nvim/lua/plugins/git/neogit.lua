---@type LazeSpec
return {
    'NeogitOrg/neogit',
    main = 'neogit',
    module = 'neogit',
    keys = {
        {
            '<Leader>gg',
            function()
                require('neogit').open({ kind = 'tab' })
                vim.cmd.tabmove()
            end,
            desc = 'Neogit',
        },
    },
    config = function()
        ---@module 'neogit.config'
        ---@type NeogitConfig
        local opts = {
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
        }
        local neogit = require('neogit')
        neogit.setup(opts)

        local augroup = vim.api.nvim_create_augroup('NeogitEvents', { clear = true })

        vim.api.nvim_create_autocmd('User', {
            pattern = 'NeogitPushComplete',
            group = augroup,
            callback = neogit.close,
            desc = 'Close Neogit after pushing',
        })

        -- vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        --     pattern = 'NeogitStatus',
        --     group = augroup,
        --     callback = function()
        --         vim.notify 'Refresh Neogit'
        --         neogit.refresh()
        --     end,
        --     desc = 'Update Neogit status on enter',
        -- })

        -- vim.api.nvim_create_autocmd('User', {
        --     pattern = 'NeogitStatusRefreshed',
        --     command = 'checktime',
        --     desc = 'Reload buffer on Neogit status refresh',
        -- })

        -- vim.api.nvim_create_autocmd('User', {
        --     pattern = {
        --         'NeogitCommitComplete',
        --         'NeogitBranchCheckout',
        --         'NeogitBranchReset',
        --         'NeogitRebase',
        --         'NeogitReset',
        --     },
        --     group = augroup,
        --     callback = neogit.refresh,
        --     desc = 'Refresh Neogit',
        -- })

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
}
