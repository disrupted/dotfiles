local M = {}

function M.setup()
    local opts = { noremap = true, silent = true }
    vim.api.nvim_set_keymap('n', '<C-x>', '<cmd>Sayonara!<CR>', opts)
end

return M
