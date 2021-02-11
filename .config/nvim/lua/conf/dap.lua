local M = {}

function M.setup() vim.g.dap_virtual_text = true end

function M.config()
    vim.cmd [[packadd nvim-dap-python]]
    vim.cmd [[packadd nvim-dap-virtual-text]]
    local dap = require('dap')

    -- Python
    require('dap-python').setup('~/.local/share/virtualenvs/debugpy/bin/python',
                                {console = 'internalConsole'})
    require('dap-python').test_runner = 'pytest'

    -- Key bindings
    local opts = {noremap = true, silent = true}
    vim.api.nvim_set_keymap('n', '<Space>ds',
                            "<cmd>lua require'dap'.continue()<CR>", opts)
    vim.api.nvim_set_keymap('n', '<Space>dq',
                            "<cmd>lua require'dap'.disconnect()<CR>", opts)
    vim.api.nvim_set_keymap('n', '<Space>do',
                            "<cmd>lua require'dap'.step_over()<CR>", opts)
    vim.api.nvim_set_keymap('n', '<Space>di',
                            "<cmd>lua require'dap'.step_into()<CR>", opts)
    vim.api.nvim_set_keymap('n', '<Space>db',
                            "<cmd>lua require'dap'.toggle_breakpoint()<CR>",
                            opts)
    vim.api.nvim_set_keymap('n', '<Space>dr',
                            "<cmd>lua require'dap'.repl.open()<CR>", opts)
    vim.api.nvim_set_keymap('n', '<Space>dn',
                            "<cmd>lua require'dap-python'.test_method()<CR>",
                            opts)
    vim.api.nvim_set_keymap('v', '<Space>ds',
                            "<ESC>:lua require'dap-python'.debug_selection()<CR>",
                            opts)
end

return M
