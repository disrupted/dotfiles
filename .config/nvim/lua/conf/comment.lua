local M = {}

function M.config()
    require('Comment').setup {
        ignore = '^$', -- ignore empty lines
    }
end

return M
