local M = {}

function M.config()
    require('Navigator').setup { auto_save = 'all', disable_on_zoom = false }

    local opts = { noremap = true, silent = true }

    vim.api.nvim_set_keymap(
        'n',
        '<C-w>j',
        '<cmd>lua require(\'Navigator\').down()<CR>',
        opts
    )
    vim.api.nvim_set_keymap(
        'n',
        '<C-w>k',
        '<cmd>lua require(\'Navigator\').up()<CR>',
        opts
    )
    vim.api.nvim_set_keymap(
        'n',
        '<C-w>h',
        '<cmd>lua require(\'Navigator\').left()<CR>',
        opts
    )
    vim.api.nvim_set_keymap(
        'n',
        '<C-w>l',
        '<cmd>lua require(\'Navigator\').right()<CR>',
        opts
    )
    -- vim.api.nvim_set_keymap('n', '<C-w>p', "<cmd>lua require('Navigator').previous()<CR>", opts)
end

return M
