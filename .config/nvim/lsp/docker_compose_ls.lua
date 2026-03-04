---@type vim.lsp.Config
return {
    cmd = {
        'bunx',
        '--bun',
        '--no-install',
        'docker-compose-langserver',
        '--stdio',
    },
    filetypes = { 'yaml.docker-compose' },
}
