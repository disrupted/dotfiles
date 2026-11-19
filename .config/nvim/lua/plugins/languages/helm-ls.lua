---@type doze.Spec
return {
    src = 'https://github.com/qvalentin/helm-ls.nvim',
    ft = 'helm',
    config = function()
        require('helm-ls').setup()
    end,
}
