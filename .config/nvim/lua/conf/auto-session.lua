local M = {}

function M.setup()
    local opts = { silent = true, noremap = true }
    vim.api.nvim_set_keymap('n', ',w', '<cmd>SaveSession<CR>', opts)
    vim.api.nvim_set_keymap('n', ',r', '<cmd>RestoreSession<CR>', opts)
end

function M.config()
    require('auto-session').setup {
        auto_session_root_dir = vim.fn.stdpath 'config' .. '/sessions/',
        auto_session_enabled = false,
    }
end

return M
