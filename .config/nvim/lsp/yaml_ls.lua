---@type vim.lsp.Config
return {
    cmd = { 'yaml-language-server', '--stdio' },
    filetypes = { 'yaml' },
    settings = {
        yaml = {
            editor = { formatOnType = false },
            schemas = {
                -- GitHub CI workflows
                -- ['https://json.schemastore.org/github-workflow.json'] = '/.github/workflows/*',
                -- Helm charts
                -- ['https://json.schemastore.org/chart.json'] = '/templates/*',
            },
            customTags = {
                -- mkdocs
                'tag:yaml.org,2002:python/name:material.extensions.emoji.twemoji',
                'tag:yaml.org,2002:python/name:material.extensions.emoji.to_svg',
                'tag:yaml.org,2002:python/name:pymdownx.superfences.fence_code_format',
            },
        },
    },
}
