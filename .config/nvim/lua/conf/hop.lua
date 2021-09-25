local M = {}

function M.setup()
    local map = require('utils').map
    map('', ',', '<cmd>HopChar1<CR>')
    map('', ',,', '<cmd>HopPattern<CR>')
end

return M
