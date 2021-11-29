local M = {}

function M.config()
    require('filetype').setup {
        overrides = {
            extensions = {
                avsc = 'json',
            },
        },
    }
end

return M
