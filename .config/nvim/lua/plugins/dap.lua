return {
    {
        'rcarriga/nvim-dap-ui',
        lazy = true,
        keys = {
            {
                '<leader>ds',
                function()
                    require('dapui').float_element(
                        'scopes',
                        { width = 80, height = 30, enter = true }
                    )
                end,
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
        end,
    },
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
                '<leader>du',
                function()
                    require('dapui').toggle {}
                end,
            },
            {
                '<leader>do',
                function()
                    require('dap').step_over()
                end,
            },
            {
                '<leader>d>',
                function()
                    require('dap').step_into()
                end,
            },
            {
                '<leader>d<',
                function()
                    require('dap').step_out()
                end,
            },
            {
                '<leader>dp',
                function()
                    require('dap').step_back() -- previous
                end,
            },
            {
                '<leader>db',
                function()
                    require('dap').toggle_breakpoint()
                end,
            },
            {
                '<leader>dB',
                function()
                    require('dap').set_breakpoint(
                        vim.fn.input 'Breakpoint condition: '
                    )
                end,
            },
            {
                '<leader>de',
                function()
                    require('dap').set_exception_breakpoints()
                end,
            },
            {
                '<leader>dl',
                function()
                    require('dap').list_breakpoints()
                end,
            },
            {
                '<leader>dr',
                function()
                    require('dap').repl.open()
                end,
            },
            -- FIXME: <ESC> first
            -- {
            --     '<leader>ds',
            --     function()
            --         require('dap-python').debug_selection()
            --     end,
            --     mode = 'v',
            -- },
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

            local dap = require 'dap'
            local dapui = require 'dapui'
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

            -- Python
            require 'dap-python'
        end,
        dependencies = {
            {
                'mfussenegger/nvim-dap-python',
                lazy = true,
                opts = {
                    include_configs = true,
                    console = 'internalConsole',
                },
                config = function(_, opts)
                    local py = require 'dap-python'
                    py.setup(
                        '~/.local/share/virtualenvs/debugpy/bin/python',
                        opts
                    )
                    py.test_runner = 'pytest'
                    local dap = require 'dap'
                    table.insert(dap.configurations.python, {
                        type = 'python',
                        request = 'launch',
                        name = 'FastAPI main.py',
                        program = function()
                            return './main.py'
                        end,
                        pythonPath = function()
                            return 'python'
                        end,
                    })
                    table.insert(dap.configurations.python, {
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
                    table.insert(dap.configurations.python, {
                        type = 'python',
                        request = 'attach',
                        name = 'Remote Python: Attach',
                        port = 5678,
                        host = '127.0.0.1',
                        mode = 'remote',
                        cwd = vim.loop.cwd(),
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
