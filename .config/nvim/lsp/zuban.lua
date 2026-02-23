---@type vim.lsp.Config
return {
    cmd = { 'zuban', 'server' },
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml' },
}
