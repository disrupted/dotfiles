local M = {}

function M.config()
    vim.filetype.add {
        extension = {
            avsc = 'json',
            jinja2 = 'htmldjango',
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
