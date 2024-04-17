vim.filetype.add {
    extension = {
        avsc = 'json',
        jinja2 = 'htmldjango',
    },
    filename = {
        ['poetry.lock'] = 'toml',
        ['.envrc'] = 'bash',
        ['Chart.lock'] = 'yaml',
        ['docker-compose.yaml'] = 'yaml.docker-compose',
        ['docker-compose.yml'] = 'yaml.docker-compose',
    },
    pattern = {
        ['.*/templates/.*%.yaml'] = 'helm',
        ['.*/templates/.*%.tpl'] = 'helm',
        ['helmfile.*.yaml'] = 'helm',
        ['.*/%.github[%w/]+.*%.yml'] = 'yaml.gha',
        ['.*/%.github[%w/]+.*%.yaml'] = 'yaml.gha',
    },
}
