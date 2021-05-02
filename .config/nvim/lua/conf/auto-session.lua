local M = {}

function M.setup()
    local opts = {silent = true, noremap = true}
    vim.api.nvim_set_keymap('n', ',w', '<cmd>SaveSession<CR>', opts)
    vim.api.nvim_set_keymap('n', ',r', '<cmd>RestoreSession<CR>', opts)
end

return M
