local M = {}

function M.setup()
    local map = require('utils').map
    map('n', '<space>R', '<cmd>lua require("persistence").load()<cr>')
end

function M.config()
    require('persistence').setup()
end

return M
