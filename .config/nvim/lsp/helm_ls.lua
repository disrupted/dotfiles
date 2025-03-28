---@type vim.lsp.Config
return {
    cmd = { 'helm_ls', 'serve' },
    filetypes = { 'helm' },
    root_markers = { 'Chart.yaml' },
}
