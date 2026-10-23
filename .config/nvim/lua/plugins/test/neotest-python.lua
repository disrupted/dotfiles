---@type LazeSpec
return {
    'nvim-neotest/neotest-python',
    main = 'neotest-python',
    module = 'neotest-python',
    keys = {
        {
            '<Leader>tu',
            function()
                require('neotest').run.run({
                    suite = false,
                    extra_args = { '--snapshot-update' },
                })
            end,
            ft = 'python',
            desc = 'Update snapshot for nearest function',
        },
        {
            '<Leader>tU',
            function()
                require('neotest').run.run({
                    vim.api.nvim_buf_get_name(0),
                    suite = false,
                    extra_args = { '--snapshot-update' },
                })
            end,
            ft = 'python',
            desc = 'Update snapshot for entire file/buffer',
        },
    },
    dependencies = { 'nvim-neotest/neotest' },
    init = function()
        require('conf.neotest.adapters').register('python', 'neotest-python')
    end,
    config = function()
        ---@module 'neotest-python.adapter'
        ---@type neotest-python._AdapterConfig
        local opts = {
            dap = { justMyCode = true },
            runner = 'pytest',
            args = {
                '-s', -- don't capture console output
                '--log-level',
                'DEBUG',
                '-vv',
                -- '--color=no',
            },
            -- pytest_discover_instances = true, -- experimental, support parametrized test cases
        }
        local adapter = require('neotest-python')(opts)
        adapter.name = 'Python'
        require('conf.neotest.adapters').attach(adapter)
    end,
}
