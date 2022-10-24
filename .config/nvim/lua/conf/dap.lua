local M = {}

function M.setup()
    local function dap_continue()
        vim.cmd [[packadd nvim-dap-virtual-text]]
        require('nvim-dap-virtual-text').setup {
            enabled = true,
            enabled_commands = false,
            highlight_changed_variables = true,
            all_references = false,
            all_frames = false,
        }
        require('dap').continue()
        -- require('dapui').open()
        vim.opt.signcolumn = 'yes:2'
    end
    local function dap_close()
        require('dap.breakpoints').clear()
        require('dap').disconnect()
        require('dap').close()
        require('dapui').close {}
        vim.opt.signcolumn = 'yes:1'
    end

    -- Key bindings
    vim.keymap.set('n', '<leader>dc', dap_continue)
    vim.keymap.set('n', '<leader>dq', dap_close)
    vim.keymap.set('n', '<leader>du', function()
        require('dapui').toggle {}
    end)
    vim.keymap.set('n', '<leader>do', function()
        require('dap').step_over()
    end)
    vim.keymap.set('n', '<leader>d>', function()
        require('dap').step_into()
    end)
    vim.keymap.set('n', '<leader>d<', function()
        require('dap').step_out()
    end)
    vim.keymap.set('n', '<leader>dp', function()
        require('dap').step_back() -- previous
    end)
    vim.keymap.set('n', '<leader>db', function()
        require('dap').toggle_breakpoint()
    end)
    vim.keymap.set('n', '<leader>dB', function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end)
    vim.keymap.set('n', '<leader>de', function()
        require('dap').set_exception_breakpoints()
    end)
    vim.keymap.set('n', '<leader>dl', function()
        require('dap').list_breakpoints()
    end)
    vim.keymap.set('n', '<leader>dr', function()
        require('dap').repl.open()
    end)
    -- FIXME: <ESC> first
    -- vim.keymap.set('v', '<leader>ds', require('dap-python').debug_selection)
end

function M.config()
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

    -- Python
    vim.cmd.packadd 'nvim-dap-python'
    local py = require 'dap-python'
    py.setup('~/.local/share/virtualenvs/debugpy/bin/python', {
        include_configs = true,
        console = 'internalConsole',
    })
    table.insert(dap.configurations.python, {
        type = 'python',
        request = 'launch',
        name = 'Launch file',
        program = '${file}',
        pythonPath = function()
            return 'python'
        end,
    })
    table.insert(dap.configurations.python, {
        type = 'python',
        request = 'launch',
        name = 'FastAPI',
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
        args = {
            'main:app',
            -- '--reload', -- doesn't work
            '--use-colors',
        },
        pythonPath = 'python',
        console = 'integratedTerminal',
    })
    py.test_runner = 'pytest'

    -- DAP UI
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
            vim.api.nvim_set_hl(ns, 'EndOfBuffer', { fg = 'bg', bg = 'bg' })
        end,
    })
    vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'dapui_console' },
        callback = function()
            vim.opt_local.laststatus = 0
        end,
    })

    vim.cmd.packadd 'nvim-dap-ui'
    require('dapui').setup {
        icons = { expanded = '', collapsed = '', current_frame = '▸' },
        layouts = {
            {
                elements = {
                    'scopes',
                    'breakpoints',
                    'stacks',
                    'watches',
                },
                size = 40,
                position = 'left',
            },
            {
                elements = {
                    'repl',
                    'console',
                },
                size = 10,
                position = 'bottom',
            },
        },
    }

    vim.api.nvim_set_hl(0, 'DapUIScope', { bold = true })
    vim.api.nvim_set_hl(0, 'DapUIDecoration', { link = 'CursorLineNr' })
    vim.api.nvim_set_hl(0, 'DapUIThread', { link = 'GitSignsAdd' })
    vim.api.nvim_set_hl(0, 'DapUIStoppedThread', { link = 'Special' })
    vim.api.nvim_set_hl(0, 'DapUILineNumber', { link = 'Normal' })
    vim.api.nvim_set_hl(0, 'DapUIType', { link = 'Type' })
    vim.api.nvim_set_hl(0, 'DapUISource', { link = 'Keyword' })
    vim.api.nvim_set_hl(0, 'DapUIWatchesEmpty', { link = 'Comment' })
    vim.api.nvim_set_hl(0, 'DapUIWatchesValue', { link = 'GitSignsAdd' })
    vim.api.nvim_set_hl(0, 'DapUIWatchesError', { link = 'DiagnosticError' })
end

return M
