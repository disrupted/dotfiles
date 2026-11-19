---@type doze.Spec
return {
    src = 'https://github.com/disrupted/kpops.nvim',
    lazy = false,
    config = function()
        ---@type kpops.Opts
        local opts = {}
        require('kpops').setup(opts)
    end,
}
