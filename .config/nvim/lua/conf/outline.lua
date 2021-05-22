local M = {}

function M.setup()
    local opts = { noremap = true, silent = true }
    vim.api.nvim_set_keymap('n', '<space>o', '<cmd>SymbolsOutline<CR>', opts)
end

function M.config()
    require('symbols-outline').setup {}
end

return M
