---@type doze.Spec
return {
    src = 'https://github.com/disrupted/github-actions.nvim',
    lazy = false,
    config = function()
        ---@type github_actions.Opts
        local opts = {}
        require('github-actions').setup(opts)
    end,
}
