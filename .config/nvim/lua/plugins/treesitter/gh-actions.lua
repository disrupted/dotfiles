---@type doze.Spec
return {
    src = 'https://github.com/Hdoc1509/gh-actions.nvim',
    -- must be on the rtp before Treesitter caches the yaml injections query
    lazy = vim.fn.argc(-1) == 0,
    -- plain yaml too: yaml.github shares its query, the first one opened caches it
    ft = { 'yaml', 'yaml.github' },
    dependencies = { 'nvim-treesitter' },
    build = function()
        require('nvim-treesitter').install('gh_actions_expressions', { force = true })
    end,
    config = function()
        require('gh-actions.tree-sitter').setup()
    end,
}
