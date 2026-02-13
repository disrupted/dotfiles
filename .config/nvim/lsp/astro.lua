---@type vim.lsp.Config
return {
    cmd = { 'bunx', '--bun', 'astro-ls', '--stdio' },
    filetypes = { 'astro' },
    root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json', '.git' },
    workspace_required = true,
    init_options = {
        typescript = { tsdk = 'node_modules/typescript/lib' },
    },
}
