return {
    {
        'mfussenegger/nvim-dap',
        keys = {
            {
                '<leader>dc',
                function()
                    require 'nvim-dap-virtual-text'
                    require('dap').continue()
                    vim.opt.signcolumn = 'yes:2'
                end,
                desc = 'continue/start debugger',
            },
            {
                '<leader>dq',
                function()
                    require('dap.breakpoints').clear()
                    require('dap').terminate()
                    require('dap').close()
                    require('dapui').close {}
                    vim.opt.signcolumn = 'yes:1'
                end,
                desc = 'close debugger',
            },
            {
                '<leader>do',
                function()
                    require('dap').step_over()
                end,
                desc = 'step over',
            },
            {
                '<leader>d>',
                function()
                    require('dap').step_into()
                end,
                desc = 'step into',
            },
            {
                '<leader>d<',
                function()
                    require('dap').step_out()
                end,
                desc = 'step out',
            },
            {
                '<leader>dp',
                function()
                    require('dap').step_back() -- previous
                end,
                desc = 'step back',
            },
            {
                '<leader>db',
                function()
                    require('dap').toggle_breakpoint()
                end,
                desc = 'toggle breakpoint',
            },
            {
                '<leader>dB',
                function()
                    require('dap').set_breakpoint(
                        vim.fn.input 'Breakpoint condition: '
                    )
                end,
                desc = 'toggle conditional breakpoint',
            },
            {
                '<leader>de',
                function()
                    require('dap').set_exception_breakpoints()
                end,
                desc = 'set exception breakpoints',
            },
            {
                '<leader>dl',
                function()
                    require('dap').list_breakpoints()
                end,
                desc = 'list breakpoints',
            },
            {
                '<leader>dr',
                function()
                    require('dap').repl.open()
                end,
                desc = 'REPL',
            },
        },
        config = function()
            local dap = require 'dap'
            dap.defaults.fallback.terminal_win_cmd = '15split new'
            dap.defaults.fallback.exception_breakpoints = { 'uncaught' } -- { 'raised', 'uncaught' }

            vim.fn.sign_define('DapBreakpoint', {
                text = '●',
                texthl = 'DiagnosticError',
            })
            vim.fn.sign_define('DapBreakpointCondition', {
                text = '',
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
        end,
        dependencies = {
            {
                'rcarriga/nvim-dap-ui',
                keys = {
                    {
                        '<leader>du',
                        function()
                            require('dapui').toggle {}
                        end,
                        desc = 'Toggle DAP UI',
                    },
                    {
                        '<leader>ds',
                        function()
                            require('dapui').float_element(
                                'scopes',
                                { width = 80, height = 30, enter = true }
                            )
                        end,
                        desc = 'Float DAP UI',
                    },
                    {
                        '<leader>de',
                        function()
                            require('dapui').eval()
                        end,
                        desc = 'Eval',
                        mode = { 'n', 'v' },
                    },
                },
                opts = {
                    icons = {
                        expanded = '',
                        collapsed = '',
                        current_frame = '▸',
                    },
                    layouts = {
                        {
                            elements = {
                                { id = 'scopes', size = 0.4 },
                                { id = 'breakpoints', size = 0.1 },
                                'stacks',
                                'watches',
                            },
                            size = 45,
                            position = 'left',
                        },
                        {
                            elements = {
                                'repl',
                                'console',
                            },
                            size = 12,
                            position = 'bottom',
                        },
                    },
                    controls = {
                        enabled = true,
                    },
                    render = {
                        max_type_length = nil,
                        max_value_lines = nil,
                    },
                },
                config = function(_, opts)
                    local ns = vim.api.nvim_create_namespace 'dap'
                    vim.api.nvim_create_autocmd('FileType', {
                        pattern = {
                            'dap-repl',
                            'dapui_scopes',
                            'dapui_breakpoints',
                            'dapui_stacks',
                            'dapui_watches',
                        },
                        callback = function()
                            vim.opt_local.signcolumn = 'no'
                            vim.api.nvim_win_set_hl_ns(0, ns)
                            vim.api.nvim_set_hl(
                                ns,
                                'EndOfBuffer',
                                { fg = 'bg', bg = 'bg' }
                            )
                        end,
                    })
                    vim.api.nvim_create_autocmd('FileType', {
                        pattern = 'dap-repl',
                        callback = function()
                            require('dap.ext.autocompl').attach()
                        end,
                    })
                    local dapui = require 'dapui'
                    dapui.setup(opts)

                    local dap = require 'dap'
                    dap.listeners.before.attach.dapui_config = function()
                        dapui.open()
                    end
                    dap.listeners.before.launch.dapui_config = function()
                        dapui.open()
                    end
                    dap.listeners.before.event_terminated.dapui_config = function()
                        dapui.close()
                    end
                    dap.listeners.before.event_exited.dapui_config = function()
                        dapui.close()
                    end
                end,
            },
            -- TODO
            -- {
            --     'folke/which-key.nvim',
            --     optional = true,
            --     opts = {
            --         defaults = {
            --             ['<leader>d'] = { name = '+debug' },
            --         },
            --     },
            -- },
            {
                'jay-babu/mason-nvim-dap.nvim',
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
                keys = {
                    -- FIXME: <ESC> first
                    -- {
                    --     '<leader>ds',
                    --     function()
                    --         require('dap-python').debug_selection()
                    --     end,
                    --     mode = 'v',
                    -- },
                },
                dependencies = {
                    {
                        'mason-nvim-dap.nvim',
                        opts = function(_, opts)
                            opts.ensure_installed = opts.ensure_installed or {}
                            vim.list_extend(opts.ensure_installed, {
                                'python',
                            })
                        end,
                    },
                },
                opts = {
                    include_configs = false,
                    console = 'internalConsole',
                },
                config = function(_, opts)
                    local py = require 'dap-python'
                    local debugpy_path = require('mason-registry')
                        .get_package('debugpy')
                        :get_install_path()
                    py.setup(debugpy_path .. '/venv/bin/python', opts)
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
                            return tonumber(vim.fn.input 'Port [5678]: ')
                                or 5678
                        end,
                        pathMappings = {
                            {
                                localRoot = function()
                                    return vim.fn.input(
                                        'Local code folder > ',
                                        vim.loop.cwd(),
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
            {
                'theHamsta/nvim-dap-virtual-text',
                lazy = true,
                opts = {
                    enabled = true,
                    enabled_commands = false,
                    highlight_changed_variables = true,
                    all_references = false,
                    all_frames = false,
                },
            },
            {
                'nvim-telescope/telescope-dap.nvim',
                config = function()
                    require('telescope').load_extension 'dap'
                end,
            },
        },
    },
}
