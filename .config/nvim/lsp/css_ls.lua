---@type vim.lsp.Config
return {
    cmd = { 'bunx', '--bun', 'vscode-css-language-server', '--stdio' },
    filetypes = { 'css', 'scss', 'less' },
    root_markers = { 'package.json', '.git' },
    init_options = { provideFormatter = false },
    settings = {
        css = {
            validate = true,
            lint = {
                unknownAtRules = 'ignore',
            },
        },
        scss = { validate = true },
        less = { validate = true },
    },
}
