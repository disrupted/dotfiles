local M = {}

function M.setup()
    local map = require('utils').map
    map('n', '<leader>op', '<cmd>Octo pr list<CR>')
    map('n', '<leader>oi', '<cmd>Octo issue list<CR>')
end

function M.config()
    require('octo').setup {
        date_format = '%Y %b %d %H:%M',
    }
end

return M
