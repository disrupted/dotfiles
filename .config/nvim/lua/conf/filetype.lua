vim.filetype.add {
    extension = {
        avsc = 'json',
        jinja2 = 'htmldjango',
        pkl = 'pkl',
        nuon = 'nu',
    },
    filename = {
        ['poetry.lock'] = 'toml',
        ['uv.lock'] = 'toml',
        ['.env'] = 'ini',
        ['.envrc'] = 'sh',
        ['Chart.lock'] = 'yaml',
        ['docker-compose.yaml'] = 'yaml.docker-compose',
        ['docker-compose.yml'] = 'yaml.docker-compose',
    },
    pattern = {
        ['.*%.gitlab%-ci%.yml'] = 'yaml.gitlab',
        ['%.env%..*'] = 'ini',
    },
}
