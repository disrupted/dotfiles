---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'mfussenegger/nvim-dap',
        init = function()
            require('which-key').add {
                {
                    '<Leader>d',
                    group = 'Debug',
                    icon = { icon = '󰃤', hl = 'DiagnosticError' },
                },
            }
        end,
        keys = {
            {
                '<Leader>dc',
                function()
                    local filetypes =
                        require('conf.workspace').project_filetypes()
                    for _, filetype in ipairs(filetypes) do
                        _ = require('conf.dap.adapters')[filetype]
                    end
                    require('dap').continue()
                    vim.opt.signcolumn = 'yes:2'
                    -- load dap-view early to use a smaller terminal window by default
                    require 'dap-view'
                    require 'nvim-dap-virtual-text'
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
                    vim.opt.signcolumn = 'yes:1'
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
                    vim.opt.signcolumn = 'yes:2'
                end,
                desc = 'Toggle breakpoint',
            },
            {
                '<Leader>dB',
                function()
                    require('dap').set_breakpoint(
                        vim.fn.input 'Breakpoint condition: '
                    )
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
                    local widgets = require 'dap.ui.widgets'
                    widgets.centered_float(
                        widgets.scopes,
                        { border = 'rounded' }
                    )
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
            local dap = require 'dap'
            -- when hitting a breakpoint use an already open window containing the breakpoint buffer
            -- instead of switching the current window to the other buffer
            dap.defaults.fallback.switchbuf = 'usevisible,usetab,uselast'
            dap.defaults.fallback.exception_breakpoints = { 'uncaught' } -- { 'raised', 'uncaught' }

            dap.listeners.after.event_exited.dap_view_config = function(_, body)
                if body and body.exitCode then
                    if body.exitCode == 0 and package.loaded['dap-view'] then
                        require('dap-view').close(true)
                    else
                        local term_winnr =
                            assert(require('dap-view.term').open_term_buf_win())
                        local term_bufnr = vim.api.nvim_win_get_buf(term_winnr)
                        vim.api.nvim_set_current_win(term_winnr)
                        local total_lines =
                            vim.api.nvim_buf_line_count(term_bufnr)
                        vim.api.nvim_win_set_cursor(
                            term_winnr,
                            { total_lines, 0 }
                        )
                    end
                end
            end
            dap.listeners.after.event_terminated.dap_view_config = function(
                _,
                body
            )
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
    },
    {
        'igorlfs/nvim-dap-view',
        cmd = { 'DapViewOpen', 'DapViewToggle', 'DapViewWatch' },
        keys = {
            {
                '<Leader>dv',
                function()
                    require('dap-view').toggle()
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
        },
        ---@module 'dap-view.config'
        ---@type Config
        ---@diagnostic disable-next-line: missing-fields
        opts = {
            ---@diagnostic disable-next-line: missing-fields
            windows = {
                ---@diagnostic disable-next-line: missing-fields
                terminal = {
                    start_hidden = true,
                    hide = { 'go' },
                },
            },
        },
        config = function(_, opts)
            require('dap-view').setup(opts)

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
    },
    {
        'rcarriga/nvim-dap-ui',
        keys = {
            {
                '<Leader>du',
                function()
                    require('dapui').toggle {}
                end,
                desc = 'Toggle DAP UI',
            },
            {
                '<Leader>ds',
                function()
                    ---@diagnostic disable-next-line: missing-fields
                    require('dapui').float_element('scopes', { enter = true })
                end,
                desc = 'Scopes',
            },
            {
                '<Leader>de',
                function()
                    require('dapui').eval()
                end,
                desc = 'Eval',
                mode = { 'n', 'v' },
            },
        },
        ---@module 'dapui.config'
        ---@type dapui.Config
        ---@diagnostic disable-next-line: missing-fields
        opts = {
            icons = {
                expanded = '',
                collapsed = '',
                current_frame = '▸',
            },
            layouts = {
                {
                    elements = {
                        { id = 'scopes', size = 0.5 },
                        { id = 'breakpoints', size = 0.1 },
                        { id = 'stacks', size = 0.2 },
                        { id = 'watches', size = 0.2 },
                    },
                    size = 0.2, -- 20% of width
                    position = 'left',
                },
                {
                    elements = {
                        -- 'repl',
                        'console',
                    },
                    size = 0.2, -- 20% of height
                    position = 'bottom',
                },
            },
            ---@diagnostic disable-next-line: missing-fields
            controls = {
                enabled = true,
                ---@diagnostic disable-next-line: missing-fields
                icons = {
                    terminate = '■',
                },
            },
            ---@diagnostic disable-next-line: missing-fields
            floating = {
                max_height = 0.6,
                max_width = 0.7,
            },
            render = {
                indent = 2,
                max_type_length = nil,
                max_value_lines = nil,
            },
        },
        config = function(_, opts)
            require('dapui').setup(opts)

            vim.api.nvim_create_autocmd('FileType', {
                pattern = {
                    'dapui_console',
                    'dapui_scopes',
                    'dapui_breakpoints',
                    'dapui_stacks',
                    'dapui_watches',
                },
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
        end,
    },
    {
        'theHamsta/nvim-dap-virtual-text',
        lazy = true,
        opts = {
            enabled = true,
            enabled_commands = false,
            highlight_changed_variables = true,
            all_references = false,
            all_frames = false,
            --- A callback that determines how a variable is displayed or whether it should be omitted
            --- @param variable Variable https://microsoft.github.io/debug-adapter-protocol/specification#Types_Variable
            --- @param buf number
            --- @param stackframe dap.StackFrame https://microsoft.github.io/debug-adapter-protocol/specification#Types_StackFrame
            --- @param node userdata tree-sitter node identified as variable definition of reference (see `:h tsnode`)
            --- @param options nvim_dap_virtual_text_options Current options for nvim-dap-virtual-text
            --- @return string|nil A text how the virtual text should be displayed or nil, if this variable shouldn't be displayed
            display_callback = function(
                variable,
                buf,
                stackframe,
                node,
                options
            )
                if #variable.value > 30 then
                    return
                end
                -- by default, strip out new line characters
                if options.virt_text_pos == 'inline' then
                    return ' = ' .. variable.value:gsub('%s+', ' ')
                else
                    return variable.name
                        .. ' = '
                        .. variable.value:gsub('%s+', ' ')
                end
            end,
        },
    },
    {
        'jay-babu/mason-nvim-dap.nvim',
        lazy = true,
        dependencies = 'mason.nvim',
        cmd = { 'DapInstall', 'DapUninstall' },
        opts = {
            automatic_installation = true,
            handlers = {},
            ensure_installed = {},
        },
    },
    {
        'mfussenegger/nvim-dap-python',
        lazy = true,
        dependencies = {
            {
                'mason-nvim-dap.nvim',
                opts = function(_, opts)
                    opts.ensure_installed = opts.ensure_installed or {}
                    table.insert(opts.ensure_installed, 'python')
                end,
            },
        },
        init = function()
            require('conf.dap.adapters').python = 'dap-python'
        end,
        ---@module 'dap-python'
        ---@type dap-python.setup.opts
        opts = {
            include_configs = false,
            console = 'internalConsole',
        },
        config = function(_, opts)
            local py = require 'dap-python'
            py.setup(vim.env.MASON .. '/packages/debugpy/venv/bin/python', opts)
            py.test_runner = 'pytest'
            local dap = require 'dap'
            local configs = dap.configurations.python or {}
            dap.configurations.python = configs
            table.insert(configs, {
                type = 'python',
                request = 'launch',
                name = 'Launch file',
                program = '${file}',
                console = opts.console,
                pythonPath = opts.pythonPath,
            })
            table.insert(configs, {
                type = 'python',
                request = 'launch',
                name = 'Launch file with arguments',
                program = '${file}',
                args = function()
                    local args_string = vim.fn.input 'Arguments: '
                    return vim.split(args_string, ' +')
                end,
                console = opts.console,
                pythonPath = opts.pythonPath,
            })
            table.insert(configs, {
                type = 'python',
                request = 'launch',
                name = 'Launch main.py',
                program = function()
                    return './main.py'
                end,
                pythonPath = opts.pythonPath,
            })
            table.insert(configs, {
                type = 'python',
                request = 'launch',
                name = 'FastAPI module',
                module = 'uvicorn',
                args = function()
                    return {
                        vim.fn.input(
                            'FastAPI app module > ',
                            'main:app',
                            'file'
                        ),
                        -- '--reload', -- doesn't work
                        '--use-colors',
                    }
                end,
                pythonPath = 'python',
                console = 'integratedTerminal',
            })
            table.insert(configs, {
                type = 'python',
                request = 'attach',
                name = 'Attach remote',
                mode = 'remote',
                host = function()
                    local host = vim.fn.input 'Host [127.0.0.1]: '
                    return host ~= '' and host or '127.0.0.1'
                end,
                port = function()
                    return tonumber(vim.fn.input 'Port [5678]: ') or 5678
                end,
                pathMappings = {
                    {
                        localRoot = function()
                            return vim.fn.input(
                                'Local code folder > ',
                                vim.uv.cwd(),
                                'file'
                            )
                        end,
                        remoteRoot = function()
                            return vim.fn.input(
                                'Container code folder > ',
                                '/',
                                'file'
                            )
                        end,
                    },
                },
            })
        end,
    },
}
