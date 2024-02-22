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
            ['Chart.lock'] = 'yaml',
        },
        pattern = {
            ['.*/templates/.*%.yaml'] = 'helm',
            ['.*/templates/.*%.tpl'] = 'helm',
            ['helmfile.*.yaml'] = 'helm',
        },
    }
end

return M
