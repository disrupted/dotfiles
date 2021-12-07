local M = {}

function M.config()
    require('filetype').setup {
        overrides = {
            extensions = {
                avsc = 'json',
            },
            complex = {
                ['templates/.*.yaml'] = 'helm',
            },
        },
    }
end

return M
