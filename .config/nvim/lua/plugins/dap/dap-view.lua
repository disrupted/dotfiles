---@type LazeSpec
return {
    'igorlfs/nvim-dap-view',
    main = 'dap-view',
    module = 'dap-view',
    dependencies = { 'mfussenegger/nvim-dap' },
    keys = {
        {
            '<Leader>dv',
            function()
                require('dap-view').toggle()
                -- require('dap-view').show_view 'scopes'
            end,
            desc = 'Toggle DAP view',
        },
        {
            '<Leader>dw',
            function()
                require('dap-view').add_expr()
            end,
            desc = 'Watch expression',
        },
        -- {
        --     '<Leader>dS',
        --     function()
        --         require('dap-view.views').switch_to_view(
        --             require('dap-view.scopes.view').show
        --         )
        --         -- require('dap-view.scopes.view').show()
        --     end,
        --     desc = 'Scopes',
        -- },
    },
    config = function()
        ---@diagnostic disable-next-line: param-type-mismatch
        require('dap-view').setup {
            ---@diagnostic disable-next-line: missing-fields
            windows = { terminal = { hide = { 'go' } } },
        }

        vim.api.nvim_create_autocmd('FileType', {
            pattern = { 'dap-view' },
            callback = function(args)
                -- scheduling is necessary because on FileType event the buffer is not assigned to a window yet
                vim.schedule(function()
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if vim.api.nvim_win_get_buf(win) == args.buf then
                            vim.wo[win].fillchars = 'eob: '
                            vim.wo[win].listchars = 'tab:  '
                            return
                        end
                    end
                end)
            end,
        })
        vim.api.nvim_create_autocmd('FileType', {
            pattern = { 'dap-view-term' },
            callback = function(args)
                -- scheduling is necessary because on FileType event the buffer is not assigned to a window yet
                vim.schedule(function()
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if vim.api.nvim_win_get_buf(win) == args.buf then
                            vim.wo[win].cursorline = false
                            vim.wo[win].signcolumn = 'no'
                            return
                        end
                    end
                end)
            end,
        })
        vim.api.nvim_create_autocmd('FileType', {
            pattern = { 'dap-view', 'dap-view-term' },
            callback = function(args)
                vim.keymap.set('n', 'q', '<C-w>q', {
                    buffer = args.buf,
                    silent = true,
                    desc = 'Close',
                })
            end,
        })
    end,
}
