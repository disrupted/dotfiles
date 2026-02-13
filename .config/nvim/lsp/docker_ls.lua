---@type vim.lsp.Config
return {
    cmd = { 'bunx', '--bun', 'docker-langserver', '--stdio' },
    filetypes = { 'dockerfile' },
}
