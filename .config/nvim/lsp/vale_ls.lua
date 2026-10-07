---@type vim.lsp.Config
return {
    cmd = { 'vale-ls' },
    filetypes = { 'asciidoc', 'markdown', 'text', 'tex', 'rst', 'html', 'xml' },
    root_markers = { '.vale.ini' },
    workspace_required = true,
}
