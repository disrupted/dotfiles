---@type LazeSpec
return {
    'haydenmeade/neotest-jest',
    main = 'neotest-jest',
    module = 'neotest-jest',
    dependencies = { 'nvim-neotest/neotest' },
    init = function()
        for _, filetype in ipairs {
            'javascript',
            'typescript',
            'javascriptreact',
            'typescriptreact',
        } do
            require('conf.neotest.adapters').register(filetype, 'neotest-jest')
        end
    end,
    config = function()
        local opts = {
            jestCommand = 'npm test --',
            env = { CI = true },
            cwd = function()
                return vim.uv.cwd()
            end,
        }
        local adapter = require 'neotest-jest'(opts)
        adapter.name = 'Jest'
        require('conf.neotest.adapters').attach(adapter)
    end,
}
