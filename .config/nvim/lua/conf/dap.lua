local M = {}

function M.setup()
    function _G.__dap_continue()
        vim.cmd [[packadd nvim-dap-virtual-text]]
        require('nvim-dap-virtual-text').setup()
        require('dap').continue()
        -- require('dapui').open()
        vim.cmd 'highlight! EndOfBuffer guibg=bg guifg=bg'
        vim.opt.signcolumn = 'yes:2'
    end
    function _G.__dap_close()
        require('dap.breakpoints').clear()
        require('dap').disconnect()
        require('dap').close()
        require('dapui').close()
        vim.cmd 'highlight clear EndOfBuffer'
        vim.opt.signcolumn = 'yes:1'
    end
    function _G.__dap_test()
        local ft = vim.bo.filetype
        if ft == 'python' then
            require('dap-python').test_method()
        elseif ft == 'typescriptreact' then
            vim.cmd [[packadd jester]]
            require('jester').run {
                cmd = 'npx jest -t \'$result\' -- $file',
                identifiers = { 'test', 'it' },
                prepend = { 'describe' },
                expressions = { 'call_expression' },
                path_to_jest = './node_modules/.bin/jest',
                terminal_cmd = ':vsplit | terminal',
                dap = {
                    type = 'node2',
                    request = 'launch',
                    cwd = vim.fn.getcwd(),
                    runtimeArgs = {
                        '--inspect-brk',
                        'node_modules/.bin/jest',
                        '--no-coverage',
                        '-t',
                        '$result',
                        '--',
                        '$file',
                    },
                    sourceMaps = true,
                    protocol = 'inspector',
                    skipFiles = { '<node_internals>/**/*.js' },
                    console = 'integratedTerminal',
                    port = 9229,
                },
            }
        else
            vim.notify('No test runner for filetype', ft)
        end
    end

    -- Key bindings
    local map = require('utils').map
    map('n', '<Space>dc', '<cmd>lua __dap_continue()<CR>')
    map('n', '<Space>dq', '<cmd>lua __dap_close()<CR>')
    map('n', '<Space>du', '<cmd>lua require("dapui").toggle()<CR>')
    map('n', '<Space>do', '<cmd>lua require("dap").step_over()<CR>')
    map('n', '<Space>d>', '<cmd>lua require("dap").step_into()<CR>')
    map('n', '<Space>d<', '<cmd>lua require("dap").step_out()<CR>')
    map('n', '<Space>db', '<cmd>lua require("dap").toggle_breakpoint()<CR>')
    map('n', '<Space>dr', '<cmd>lua require("dap").repl.open()<CR>')
    map('n', '<Space>t', '<cmd>lua __dap_test()<CR>')
    map(
        'v',
        '<Space>ds',
        '<ESC>:lua require("dap-python").debug_selection()<CR>'
    )
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
        sidebar = {
            open_on_start = false,
            elements = {
                {
                    id = 'scopes',
                    size = 0.25,
                },
                { id = 'stacks', size = 0.25 },
                { id = 'watches', size = 0.25 },
            },
            size = 40,
            position = 'left',
        },
    }

    vim.cmd [[
        highlight! link DapUIScope bold
        highlight! link DapUIDecoration CursorLineNr
        highlight! link DapUIThread GitSignsAdd
        highlight! link DapUIStoppedThread Special
        highlight! link DapUILineNumber Normal
        highlight! link DapUIType Type
        highlight! link DapUISource Keyword
        highlight! link DapUIWatchesEmpty Comment
        highlight! link DapUIWatchesValue GitSignsAdd
        highlight! link DapUIWatchesError DiagnosticError
    ]]
end

return M
