local M = {}

function M.config()
    vim.filetype.add {
        extension = {
            avsc = 'json',
        },
        filename = {
            ['poetry.lock'] = 'toml',
            ['.envrc'] = 'bash',
        },
        pattern = {
            ['templates/.*%.yaml'] = 'helm',
        },
    }
end

return M
