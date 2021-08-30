local M = {}

function M.setup()
    local opts = { silent = true, noremap = true }
    vim.api.nvim_set_keymap(
        'n',
        '\'',
        '<cmd>lua require("neoclip"); require("telescope").extensions.neoclip.default()<CR>',
        opts
    )
end

function M.config()
    require('neoclip').setup()
end

return M
