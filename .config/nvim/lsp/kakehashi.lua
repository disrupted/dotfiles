---@type vim.lsp.Config
return {
    cmd = { 'kakehashi' },
    filetypes = { 'markdown', 'lua', 'rust', 'python' },
    root_markers = { 'kakehashi.toml', '.git' },
    workspace_required = false,
    init_options = {
        autoInstall = false,
        -- languageServers = {
        --     ['lua_ls'] = {
        --         cmd = { 'lua-language-server' },
        --         languages = { 'lua' },
        --     },
        -- },
        languages = {
            markdown = {
                bridge = { lua_ls = { enabled = true } },
            },
        },
    },
}
