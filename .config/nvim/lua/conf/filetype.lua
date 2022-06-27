local M = {}

function M.config()
    vim.filetype.add {
        extension = {
            avsc = 'json',
        },
        pattern = {
            ['templates/.*%.yaml'] = 'helm',
        },
    }
end

return M
