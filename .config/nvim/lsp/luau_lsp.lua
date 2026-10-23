---@type vim.lsp.Config
return {
    cmd = {
        'luau-lsp',
        'lsp',
        '--definitions=' .. vim.fs.normalize('~/dev/maki/plugins/maki.d.luau'),
    },
    filetypes = { 'luau' },
    root_markers = { '.git', 'init.lua' },
    settings = {
        ['luau-lsp'] = {
            platform = { type = 'standard' },
            sourcemap = { enabled = false },
        },
    },
}
