local M = {}

function M.setup()
    local map = require('utils').map
    map('n', '<space>o', '<cmd>SymbolsOutline<CR>')
end

function M.config()
    require('symbols-outline').setup {}
end

return M
