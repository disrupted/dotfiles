local M = {}

function M.setup()
    local opts = { silent = true, noremap = true }
    vim.api.nvim_set_keymap(
        'n',
        '<C-x>',
        '<cmd>Bdelete<CR>',
        opts
    )
end

return M

