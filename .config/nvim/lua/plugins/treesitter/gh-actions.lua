---@type LazeSpec
return {
    'Hdoc1509/gh-actions.nvim',
    lazy = false,
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    build = function()
        require('nvim-treesitter').install(
            'gh_actions_expressions',
            { force = true }
        )
    end,
    config = function()
        require('gh-actions.tree-sitter').setup()
    end,
}
