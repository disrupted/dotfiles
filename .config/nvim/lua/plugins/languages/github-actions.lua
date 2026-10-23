---@type LazeSpec
return {
    'disrupted/github-actions.nvim',
    main = 'github-actions',
    module = 'github-actions',
    lazy = false,
    ---@module 'github-actions.config'
    ---@type github_actions.Opts
    opts = {
        token_provider = function(callback)
            callback(vim.env.GITHUB_TOKEN)
        end,
    },
}
