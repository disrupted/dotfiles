local M = {}

function M.setup()
    local opts = {noremap = true, silent = true}
    vim.api.nvim_set_keymap('', 'q', '<cmd>HopChar1<CR>', opts)
    vim.api.nvim_set_keymap('', '<C-q>', '<cmd>HopPattern<CR>', opts)
end

return M
