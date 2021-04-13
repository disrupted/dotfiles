local M = {}

function M.config()
    vim.cmd [[packadd Navigator.nvim]]
    require'Navigator'.setup()

    local opts = { noremap = true, silent = true }

    vim.api.nvim_set_keymap('n', '<C-j>', "<cmd>lua require('Navigator').down()<CR>", opts)
    vim.api.nvim_set_keymap('n', '<C-k>', "<cmd>lua require('Navigator').up()<CR>", opts)
    vim.api.nvim_set_keymap('n', '<C-h>', "<cmd>lua require('Navigator').left()<CR>", opts)
    vim.api.nvim_set_keymap('n', '<C-l>', "<cmd>lua require('Navigator').right()<CR>", opts)
    vim.api.nvim_set_keymap('n', '<C-p>', "<cmd>lua require('Navigator').previous()<CR>", opts)
end

return M
