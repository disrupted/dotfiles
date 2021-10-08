local M = {}

function M.setup()
    local map = require('utils').map
    map('n', '<space>g', '<cmd>lua require("neogit").open()<CR>')
end

function M.config()
    require('neogit').setup {
        signs = {
            section = { '', '' },
            item = { '', '' },
            hunk = { '', '' },
        },
        integrations = {
            diffview = true,
        },
    }
end

return M
