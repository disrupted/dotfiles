local M = {}

function M.setup()
    local map = require('utils').map
    map(
        'n',
        '\'',
        '<cmd>lua require("neoclip"); require("telescope").extensions.neoclip.default()<CR>'
    )
end

function M.config()
    require('neoclip').setup()
end

return M
