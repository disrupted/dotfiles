local M = {}

function M.setup()
    local opts = { noremap = true, silent = true }
    vim.api.nvim_set_keymap('n', '<space>g', '<cmd>Neogit<CR>', opts)
end

function M.config()
    require('neogit').setup {
        signs = {
            section = { '', '' },
            item = { '▸', '▾' },
            hunk = { '', '' },
        },
    }
end

return M
