---@type LazeSpec
return {
    'emrearmagan/atlas.nvim',
    main = 'atlas',
    module = 'atlas',
    cmd = 'Atlas',
    ---@module 'atlas'
    ---@type AtlasConfig
    opts = {
        providers = {
            ---@type AtlasGitHubConfig
            github = {
                cache_ttl = 300,
            },
        },
    },
}
