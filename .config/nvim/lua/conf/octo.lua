local M = {}

-- function M.setup()
--     local opts = { silent = true, noremap = true }
--     vim.api.nvim_set_keymap('n', '<space>o', '<cmd>Octo<CR>', opts)
-- end

function M.config()
    require('octo').setup {
        date_format = '%Y %b %d %H:%M',
    }
end

return M
