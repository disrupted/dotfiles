---@type vim.lsp.Config
return {
    cmd = { 'helm_ls', 'serve' },
    filetypes = { 'helm', 'yaml.helm-values', 'yaml.helm-chartfile' },
    root_markers = { 'Chart.yaml' },
    settings = {
        ['helm-ls'] = {
            yamlls = {
                path = {
                    'bunx',
                    '--bun',
                    '--no-install',
                    'yaml-language-server',
                },
            },
        },
    },
}
