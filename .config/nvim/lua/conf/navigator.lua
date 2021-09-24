local M = {}

function M.setup()
    if os.getenv 'TMUX' then
        local opts = { noremap = true, silent = true }
        vim.api.nvim_set_keymap(
            'n',
            '<C-w>j',
            '<cmd>lua require("Navigator").down()<CR>',
            opts
        )
        vim.api.nvim_set_keymap(
            'n',
            '<C-w>k',
            '<cmd>lua require("Navigator").up()<CR>',
            opts
        )
        vim.api.nvim_set_keymap(
            'n',
            '<C-w>h',
            '<cmd>lua require("Navigator").left()<CR>',
            opts
        )
        vim.api.nvim_set_keymap(
            'n',
            '<C-w>l',
            '<cmd>lua require("Navigator").right()<CR>',
            opts
        )
    end
end

function M.config()
    require('Navigator').setup { auto_save = 'all', disable_on_zoom = false }
end

return M
