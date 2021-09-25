local M = {}

-- function M.setup()
--     local map = require('utils').map
--     map('n', '<space>o', '<cmd>Octo<CR>')
-- end

function M.config()
    require('octo').setup {
        date_format = '%Y %b %d %H:%M',
    }
end

return M
