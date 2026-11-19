---@type doze.Spec
return {
    src = 'https://github.com/tiagovla/scope.nvim', -- tab-scoped buffers
    event = 'TabNew',
    config = function()
        require('scope').setup({})
    end,
}
