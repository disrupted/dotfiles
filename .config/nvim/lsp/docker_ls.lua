---@type vim.lsp.Config
return {
    cmd = { 'docker-langserver', '--stdio' },
    filetypes = { 'dockerfile' },
}
