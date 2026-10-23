---@type LazeSpec
return {
    'mrcjkb/rustaceanvim',
    main = 'rustaceanvim',
    module = 'rustaceanvim',
    ft = 'rust',
    dependencies = { 'nvim-neotest/neotest' },
    init = function()
        require('conf.neotest.adapters').register('rust', 'rustaceanvim.neotest')
    end,
    config = function()
        ---@module 'rustaceanvim.config'
        ---@type rustaceanvim.Opts
        local opts = {}
        vim.g.rustaceanvim = opts

        local adapter = require('rustaceanvim.neotest')()
        adapter.name = 'Rust'
        require('conf.neotest.adapters').attach(adapter)
    end,
}
