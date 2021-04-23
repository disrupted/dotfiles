local M = {}

function M.setup()
    local opts = {noremap = true, silent = true}
    vim.api.nvim_set_keymap('n', 'q', "<cmd>HopWord<CR>", opts)
    vim.api.nvim_set_keymap('n', '<C-q>', "<cmd>HopPattern<CR>", opts)
end

return M
