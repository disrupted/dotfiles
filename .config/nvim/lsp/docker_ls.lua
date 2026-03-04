---@type vim.lsp.Config
return {
    cmd = { 'bunx', '--bun', '--no-install', 'docker-langserver', '--stdio' },
    filetypes = { 'dockerfile' },
}
