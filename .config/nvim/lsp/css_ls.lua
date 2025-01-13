---@type vim.lsp.Config
return {
    cmd = { 'vscode-css-language-server', '--stdio' },
    filetypes = { 'css', 'scss', 'less' },
    root_markers = { 'package.json', '.git' },
    init_options = { provideFormatter = false },
    settings = {
        css = { validate = true },
        scss = { validate = true },
        less = { validate = true },
    },
}
