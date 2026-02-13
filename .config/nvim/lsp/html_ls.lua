---@type vim.lsp.Config
return {
    cmd = { 'bunx', '--bun', 'vscode-html-language-server', '--stdio' },
    filetypes = { 'html', 'templ' },
    root_markers = { 'package.json', '.git' },
    init_options = {
        provideFormatter = false,
        embeddedLanguages = { css = true, javascript = true },
        configurationSection = { 'html', 'css', 'javascript' },
    },
    settings = {
        html = {
            hover = {
                documentation = true,
                references = true,
            },
        },
    },
}
