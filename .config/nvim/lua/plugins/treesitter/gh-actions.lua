---@type doze.Spec
return {
    src = 'https://github.com/Hdoc1509/gh-actions.nvim',
    lazy = false,
    dependencies = { 'nvim-treesitter' },
    build = function()
        require('nvim-treesitter').install('gh_actions_expressions', { force = true })
    end,
    config = function()
        require('gh-actions.tree-sitter').setup()
    end,
}
