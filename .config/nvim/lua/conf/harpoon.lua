local M = {}

function M.setup()
    local opts = { silent = true, noremap = true }
    vim.api.nvim_set_keymap(
        'n',
        '"',
        '<cmd>lua require("harpoon.ui").toggle_quick_menu()<CR>',
        opts
    )
    vim.api.nvim_set_keymap(
        'n',
        'M',
        '<cmd>lua require("harpoon.mark").toggle_file()<CR>',
        opts
    )

    -- Use common mappings to close popup
    vim.cmd [[ autocmd FileType harpoon nnoremap <buffer> q :q<cr> ]]
    vim.cmd [[ autocmd FileType harpoon nnoremap <buffer> <esc> :q<cr> ]]
end

function M.config()
    require('harpoon').setup {}
end

return M
