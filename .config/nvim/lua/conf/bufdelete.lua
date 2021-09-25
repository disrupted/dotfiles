local M = {}

function M.setup()
    local map = require('utils').map
    map('n', '<C-x>', '<cmd>Bdelete<CR>')
end

return M
