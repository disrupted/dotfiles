vim.filetype.add {
    extension = {
        avsc = 'json',
        jinja2 = 'htmldjango',
        pkl = 'pkl',
        nuon = 'nu',
        sb = 'scheme', -- macOS seatbelt (sandbox) profiles
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
        ['mise%.?%a*%.toml'] = 'toml.mise', -- mise.toml, mise.<env>.toml
        ['${HOME}/%.config/mise/config%.toml'] = 'toml.mise',
        ['.*%.gitlab%-ci%.yml'] = 'yaml.gitlab',
        ['%.env%..*'] = 'ini',
    },
}
