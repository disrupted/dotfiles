local M = {}

function M.setup()
    local function dap_continue()
        vim.cmd [[packadd nvim-dap-virtual-text]]
        require('nvim-dap-virtual-text').setup()
        require('dap').continue()
        -- require('dapui').open()
        vim.cmd 'highlight! EndOfBuffer guibg=bg guifg=bg'
        vim.opt.signcolumn = 'yes:2'
    end
    local function dap_close()
        require('dap.breakpoints').clear()
        require('dap').disconnect()
        require('dap').close()
        require('dapui').close()
        vim.api.nvim_set_hl(0, 'EndOfBuffer', {})
        vim.opt.signcolumn = 'yes:1'
    end
    -- NOTICE: disabled in favor of neotest
    -- local function dap_test()
    --     local ft = vim.bo.filetype
    --     if ft == 'python' then
    --         require('dap-python').test_method()
    --     elseif ft == 'typescriptreact' then
    --         vim.cmd [[packadd jester]]
    --         require('jester').run {
    --             cmd = 'npx jest -t \'$result\' -- $file',
    --             identifiers = { 'test', 'it' },
    --             prepend = { 'describe' },
    --             expressions = { 'call_expression' },
    --             path_to_jest = './node_modules/.bin/jest',
    --             terminal_cmd = ':vsplit | terminal',
    --             dap = {
    --                 type = 'node2',
    --                 request = 'launch',
    --                 cwd = vim.fn.getcwd(),
    --                 runtimeArgs = {
    --                     '--inspect-brk',
    --                     'node_modules/.bin/jest',
    --                     '--no-coverage',
    --                     '-t',
    --                     '$result',
    --                     '--',
    --                     '$file',
    --                 },
    --                 sourceMaps = true,
    --                 protocol = 'inspector',
    --                 skipFiles = { '<node_internals>/**/*.js' },
    --                 console = 'integratedTerminal',
    --                 port = 9229,
    --             },
    --         }
    --     else
    --         vim.notify('No test runner for filetype', ft)
    --     end
    -- end

    -- Key bindings
    vim.keymap.set('n', '<Space>dc', dap_continue)
    vim.keymap.set('n', '<Space>dq', dap_close)
    vim.keymap.set('n', '<Space>du', require('dapui').toggle)
    vim.keymap.set('n', '<Space>do', require('dap').step_over)
    vim.keymap.set('n', '<Space>d>', require('dap').step_into)
    vim.keymap.set('n', '<Space>d<', require('dap').step_out)
    vim.keymap.set('n', '<Space>db', require('dap').toggle_breakpoint)
    vim.keymap.set('n', '<Space>dr', require('dap').repl.open)
    -- vim.keymap.set('n', '<Space>t', dap_test)
    -- FIXME: <ESC> first
    -- vim.keymap.set('v', '<Space>ds', require('dap-python').debug_selection)
end

function M.config()
    local dap = require 'dap'
    dap.defaults.fallback.terminal_win_cmd = '15split new'

    vim.fn.sign_define('DapBreakpoint', {
        text = '●', -- 
        texthl = 'DiagnosticError',
    })
    vim.fn.sign_define('DapStopped', {
        text = '■',
        texthl = 'Special',
    })

    -- Python
    vim.cmd [[packadd nvim-dap-python]]
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
        program = vim.fn.getcwd() .. '/main.py',
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
            -- '--reload',
            '--use-colors',
        },
        pythonPath = 'python',
        console = 'integratedTerminal',
    })
    py.test_runner = 'pytest'

    -- DAP UI
    vim.cmd [[autocmd FileType dap-repl,dapui_scopes,dapui_breakpoints,dapui_stacks,dapui_watches setlocal signcolumn=no]]

    vim.cmd [[packadd nvim-dap-ui]]
    require('dapui').setup {
        icons = { expanded = '', collapsed = '' },
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

    vim.api.nvim_set_hl(0, 'DapUIScope', { link = 'bold' })
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
