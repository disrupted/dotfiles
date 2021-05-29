local M = {}

function M.setup()
    vim.g.dap_virtual_text = true
end

function M.config()
    local dap = require 'dap'

    vim.fn.sign_define('DapBreakpoint', {
        text = '',
        texthl = 'LspDiagnosticsError',
        linehl = '',
        numhl = '',
    })

    -- Python
    vim.cmd [[packadd nvim-dap-python]]
    require('dap-python').setup('~/.local/share/virtualenvs/debugpy/bin/python', {
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
    require('dap-python').test_runner = 'pytest'

    function _G.__dap_start()
        dap.continue()
        vim.opt.signcolumn = 'yes:2'
    end
    function _G.__dap_exit()
        dap.disconnect()
        vim.opt.signcolumn = 'yes:1'
    end
    -- Key bindings
    local opts = { noremap = true, silent = true }
    vim.api.nvim_set_keymap(
        'n',
        '<Space>ds',
        '<cmd>lua __dap_start()<CR>',
        opts
    )
    vim.api.nvim_set_keymap('n', '<Space>dq', '<cmd>lua __dap_exit()<CR>', opts)
    vim.api.nvim_set_keymap(
        'n',
        '<Space>do',
        '<cmd>lua require\'dap\'.step_over()<CR>',
        opts
    )
    vim.api.nvim_set_keymap(
        'n',
        '<Space>di',
        '<cmd>lua require\'dap\'.step_into()<CR>',
        opts
    )
    vim.api.nvim_set_keymap(
        'n',
        '<Space>db',
        '<cmd>lua require\'dap\'.toggle_breakpoint()<CR>',
        opts
    )
    vim.api.nvim_set_keymap(
        'n',
        '<Space>dr',
        '<cmd>lua require\'dap\'.repl.open()<CR>',
        opts
    )
    vim.api.nvim_set_keymap(
        'n',
        '<Space>dn',
        '<cmd>lua require\'dap-python\'.test_method()<CR>',
        opts
    )
    vim.api.nvim_set_keymap(
        'v',
        '<Space>ds',
        '<ESC>:lua require\'dap-python\'.debug_selection()<CR>',
        opts
    )
end

return M
