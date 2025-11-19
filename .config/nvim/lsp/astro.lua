---@type vim.lsp.Config
return {
    cmd = { 'astro-ls', '--stdio' },
    filetypes = { 'astro' },
    root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json', '.git' },
    init_options = {
        typescript = { tsdk = 'node_modules/typescript/lib' },
    },
}
