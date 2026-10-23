---@type LazeSpec
return {
    'mfussenegger/nvim-dap',
    main = 'dap',
    module = 'dap',
    init = function()
        require('which-key').add({
            {
                '<Leader>d',
                group = 'Debug',
                mode = { 'n', 'v' },
                icon = { icon = '󰃤', hl = 'DiagnosticError' },
            },
        })
    end,
    keys = {
        {
            '<Leader>dc',
            function()
                require('conf.dap.adapters').load_project()
                require('dap').continue()
                vim.o.signcolumn = 'yes:2'
                -- load dap-view early to use a smaller terminal window by default
                require('dap-view')
                require('nvim-dap-virtual-text')
            end,
            desc = 'Continue/start',
        },
        {
            '<Leader>dr',
            function()
                require('dap').restart()
            end,
            desc = 'Restart',
        },
        {
            '<Leader>dq',
            function()
                require('dap').terminate()
            end,
            desc = 'Close',
        },
        {
            '<Leader>dQ',
            function()
                require('dap.breakpoints').clear()
                vim.o.signcolumn = 'yes:1'
            end,
            desc = 'Clear breakpoints',
        },
        {
            '<Leader>do',
            function()
                require('dap').step_over()
            end,
            desc = 'Step over',
        },
        {
            '<Leader>d>',
            function()
                require('dap').step_into()
            end,
            desc = 'Step into',
        },
        {
            '<Leader>d<',
            function()
                require('dap').step_out()
            end,
            desc = 'Step out',
        },
        {
            '<Leader>dp', -- previous
            function()
                require('dap').step_back()
            end,
            desc = 'Step back',
        },
        {
            '<Leader>db',
            function()
                require('dap').toggle_breakpoint()
                vim.o.signcolumn = 'yes:2'
            end,
            desc = 'Toggle breakpoint',
        },
        {
            '<Leader>dB',
            function()
                require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))
            end,
            desc = 'Toggle conditional breakpoint',
        },
        {
            '<Leader>de',
            function()
                require('dap').set_exception_breakpoints()
            end,
            desc = 'Set exception breakpoints',
        },
        {
            '<Leader>dl',
            function()
                require('dap').list_breakpoints()
            end,
            desc = 'List breakpoints',
        },
        { -- DAP UI looks better
            '<Leader>dS',
            function()
                local widgets = require('dap.ui.widgets')
                widgets.centered_float(widgets.scopes, { border = 'rounded' })
            end,
            desc = 'Scopes',
        },
        {
            '<Leader>dE',
            function()
                require('dap.ui.widgets').hover()
            end,
            desc = 'Eval',
        },
        {
            '<Leader>dR',
            function()
                require('dap').repl.open()
            end,
            desc = 'REPL',
        },
    },
    config = function()
        local dap = require('dap')
        -- when hitting a breakpoint use an already open window containing the breakpoint buffer
        -- instead of switching the current window to the other buffer
        dap.defaults.fallback.switchbuf = 'usevisible,usetab,uselast'
        dap.defaults.fallback.exception_breakpoints = { 'uncaught' } -- { 'raised', 'uncaught' }

        dap.listeners.after.event_exited.dap_view_config = function(_, body)
            if body and body.exitCode then
                if body.exitCode == 0 and package.loaded['dap-view'] then
                    require('dap-view').close(true)
                else
                    -- TODO: update
                    -- local term_winnr =
                    --     assert(require('dap-view.term').open_term_buf_win())
                    -- local term_bufnr = vim.api.nvim_win_get_buf(term_winnr)
                    -- vim.api.nvim_set_current_win(term_winnr)
                    -- local total_lines =
                    --     vim.api.nvim_buf_line_count(term_bufnr)
                    -- vim.api.nvim_win_set_cursor(
                    --     term_winnr,
                    --     { total_lines, 0 }
                    -- )
                end
            end
        end
        dap.listeners.after.event_terminated.dap_view_config = function(_, body)
            if body and body.restart then
                -- TODO: if dap-view open keep it open
                return
            end
        end
        -- some adapters send disconnect response instead of terminated
        dap.listeners.after.disconnect.dap_view_config = function()
            require('dap-view').close(true)
        end

        local function close_dapui()
            if package.loaded.dapui then
                require('dapui').close()
            end
        end
        dap.listeners.after.event_exited.dapui_config = function()
            close_dapui()
        end
        dap.listeners.after.event_terminated.dapui_config = function()
            close_dapui()
        end
        dap.listeners.after.disconnect.dapui_config = function()
            close_dapui()
        end

        vim.fn.sign_define('DapBreakpoint', {
            text = '●',
            texthl = 'DiagnosticError',
        })
        vim.fn.sign_define('DapBreakpointCondition', {
            text = '◌', -- ○
            texthl = 'DiagnosticError',
        })
        vim.fn.sign_define('DapLogPoint', {
            text = '•',
            texthl = 'DiagnosticInfo',
        })
        vim.fn.sign_define('DapStopped', {
            text = '■',
            texthl = 'Special',
        })

        vim.api.nvim_create_autocmd('FileType', {
            pattern = { 'dap-repl' },
            callback = function(args)
                -- scheduling is necessary because on FileType event the buffer is not assigned to a window yet
                vim.schedule(function()
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if vim.api.nvim_win_get_buf(win) == args.buf then
                            vim.wo[win].fillchars = 'eob: '
                            vim.wo[win].statuscolumn = ''
                            return
                        end
                    end
                end)
            end,
        })
        vim.api.nvim_create_autocmd('FileType', {
            pattern = 'dap-repl',
            callback = function()
                require('dap.ext.autocompl').attach()
            end,
        })
        vim.api.nvim_create_autocmd('FileType', {
            pattern = { 'dap-float', 'dap-repl' },
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
