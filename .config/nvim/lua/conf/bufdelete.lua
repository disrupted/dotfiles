local M = {}

function M.setup()
    vim.keymap.set('n', '<C-x>', '<cmd>Bdelete<CR>')
end

return M
