---@type vim.lsp.Config
return {
    cmd = { 'bunx', '--bun', 'docker-compose-langserver', '--stdio' },
    filetypes = { 'yaml.docker-compose' },
}
