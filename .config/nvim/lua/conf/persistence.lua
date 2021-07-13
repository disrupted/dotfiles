local M = {}

function M.setup()
    local opts = { silent = true, noremap = true }
    vim.api.nvim_set_keymap(
        'n',
        ',r',
        '<cmd>lua require("persistence").load()<cr>',
        opts
    )
end

function M.config()
    require('persistence').setup()
end

return M
