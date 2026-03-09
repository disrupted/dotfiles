---@type vim.lsp.Config
return {
    cmd = { 'tinymist' },
    filetypes = { 'typst' },
    root_markers = { '.git' },
    workspace_required = false,
    settings = {
        formatterMode = 'typstyle',
    },
}
