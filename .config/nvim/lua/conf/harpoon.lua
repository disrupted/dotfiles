local M = {}

function M.setup()
    local opts = { silent = true, noremap = true }
    vim.api.nvim_set_keymap(
        'n',
        '<space>h',
        '<cmd>lua require"harpoon.ui".toggle_quick_menu()<CR>',
        opts
    )
    vim.cmd [[ autocmd FileType harpoon nnoremap <buffer> q :q<cr> ]]

    -- vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':q', {
    --     silent = true,
    --     noremap = true,
    --     nowait = true,
    -- })
end

function M.config()
    require('harpoon').setup {}
end

return M
