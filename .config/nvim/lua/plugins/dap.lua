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
                    _ = require('conf.dap.adapters')[vim.bo.filetype]
                    require 'nvim-dap-virtual-text'
                    -- HACK: otherwise terminal_win_cmd isn't set and dap terminal is used instead of dapui console
                    require 'dapui'
                    require('dap').continue()
                    vim.opt.signcolumn = 'yes:2'
                end,
                desc = 'Continue/start debugger',
            },
            {
                '<Leader>dq',
                function()
                    require('dap').terminate()
                    require('dap').close()
                    require('dapui').close {}
                end,
                desc = 'Close debugger',
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
            {
                '<Leader>dr',
                function()
                    require('dap').repl.open()
                end,
                desc = 'REPL',
            },
        },
        config = function()
            local dap = require 'dap'
            -- dap.defaults.fallback.terminal_win_cmd = '15split new' -- use DAP UI console instead
            dap.defaults.fallback.exception_breakpoints = { 'uncaught' } -- { 'raised', 'uncaught' }
            dap.listeners.before.attach.dapui_config = function()
                require('dapui').open()
            end
            dap.listeners.before.launch.dapui_config = function()
                require('dapui').open()
            end
            dap.listeners.before.event_terminated.dapui_config = function()
                require('dapui').close()
            end
            dap.listeners.before.event_exited.dapui_config = function()
                require('dapui').close()
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
                desc = 'Float DAP UI',
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
                indent = 0,
                max_type_length = nil,
                max_value_lines = nil,
            },
        },
        config = function(_, opts)
            -- FIXME: does not work
            --[[ vim.api.nvim_create_autocmd('FileType', {
                pattern = {
                    'dap-repl',
                    'dapui_console',
                    'dapui_scopes',
                    'dapui_breakpoints',
                    'dapui_stacks',
                    'dapui_watches',
                },
                callback = function(args)
                    local buf = args.buf
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if vim.api.nvim_win_get_buf(win) == buf then
                            vim.api.nvim_set_option_value(
                                'fillchars',
                                'eob: ',
                                { win = win }
                            )
                            vim.api.nvim_set_option_value(
                                'statuscolumn',
                                '',
                                { win = win }
                            )
                            return
                        end
                    end
                end,
            }) ]]
            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'dap-repl',
                callback = function()
                    require('dap.ext.autocompl').attach()
                end,
            })

            require('dapui').setup(opts)
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
