local M = {}

function M.setup()
    local opts = { noremap = true, silent = true }
    vim.api.nvim_set_keymap('', ',', '<cmd>HopChar1<CR>', opts)
    vim.api.nvim_set_keymap('', ',,', '<cmd>HopPattern<CR>', opts)
end

return M
