local M = {}

function M.setup()
    function _G.__dap_start()
        require('dap').continue()
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

    -- Key bindings
    local opts = { noremap = true, silent = true }
    local map = vim.api.nvim_set_keymap
    map('n', '<Space>ds', '<cmd>lua __dap_start()<CR>', opts)
    map('n', '<Space>dq', '<cmd>lua __dap_close()<CR>', opts)
    map('n', '<Space>do', '<cmd>lua require("dap").step_over()<CR>', opts)
    map('n', '<Space>di', '<cmd>lua require("dap").step_into()<CR>', opts)
    map(
        'n',
        '<Space>db',
        '<cmd>lua require("dap").toggle_breakpoint()<CR>',
        opts
    )
    map('n', '<Space>dr', '<cmd>lua require("dap").repl.open()<CR>', opts)
    map(
        'n',
        '<Space>dn',
        '<cmd>lua require("dap-python").test_method()<CR>',
        opts
    )
    map(
        'v',
        '<Space>ds',
        '<ESC>:lua require("dap-python").debug_selection()<CR>',
        opts
    )
end

function M.config()
    vim.g.dap_virtual_text = true
    local dap = require 'dap'

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
        console = 'internalConsole',
    })
    dap.configurations.python = {
        {
            type = 'python',
            request = 'launch',
            name = 'Launch file',
            program = '${file}',
            pythonPath = function()
                return 'python'
            end,
        },
    }
    py.test_runner = 'pytest'

    -- DAP UI
    vim.cmd [[autocmd FileType dap-repl,dapui_scopes,dapui_breakpoints,dapui_stacks,dapui_watches setlocal signcolumn=no]]

    vim.cmd [[packadd nvim-dap-ui]]
    require('dapui').setup {
        sidebar = {
            open_on_start = true,
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
