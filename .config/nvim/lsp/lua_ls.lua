---@type vim.lsp.Config
return {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    root_markers = {
        '.luarc.json',
        '.luarc.jsonc',
        '.stylua.toml',
        'stylua.toml',
        '.git',
    },
    settings = {
        Lua = {
            completion = {
                callSnippet = 'Replace',
            },
            workspace = { checkThirdParty = false },
            codeLens = { enable = true },
            telemetry = { enable = false },
            doc = { privateName = { '^_' } },
            diagnostics = {
                unusedLocalExclude = { '_*' },
            },
            format = { enable = false },
            hint = {
                enable = true,
                setType = false,
                paramType = true,
                arrayIndex = 'Disable',
            },
        },
    },
}
