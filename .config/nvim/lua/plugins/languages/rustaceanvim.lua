---@type doze.Spec
return {
    src = 'https://github.com/mrcjkb/rustaceanvim',
    ft = 'rust',
    dependencies = { 'neotest' },
    init = function()
        require('conf.neotest.adapters').register('rust', 'rustaceanvim.neotest')
    end,
    config = function()
        ---@module 'rustaceanvim.config'
        ---@type rustaceanvim.Opts
        local opts = {}
        vim.g.rustaceanvim = opts

        ---@diagnostic disable-next-line: call-non-callable
        local adapter = require('rustaceanvim.neotest')()
        adapter.name = 'Rust'
        require('conf.neotest.adapters').attach(adapter)
    end,
}
