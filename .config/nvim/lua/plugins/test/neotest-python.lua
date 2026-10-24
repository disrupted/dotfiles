---@type LazeSpec
return {
    'nvim-neotest/neotest-python',
    main = 'neotest-python',
    module = 'neotest-python',
    dependencies = { 'nvim-neotest/neotest' },
    init = function()
        require('conf.neotest.adapters').register('python', 'neotest-python')
        local group =
            vim.api.nvim_create_augroup('neotest_python_keys', { clear = true })
        local function set(buf)
            local function map(lhs, rhs, desc)
                vim.keymap.set('n', lhs, rhs, {
                    buffer = buf,
                    desc = desc,
                })
            end

            map('<Leader>tu', function()
                require('neotest').run.run({
                    suite = false,
                    extra_args = { '--snapshot-update' },
                })
            end, 'Update snapshot for nearest function')
            map('<Leader>tU', function()
                require('neotest').run.run({
                    vim.api.nvim_buf_get_name(0),
                    suite = false,
                    extra_args = { '--snapshot-update' },
                })
            end, 'Update snapshot for entire file/buffer')
        end

        vim.api.nvim_create_autocmd('FileType', {
            group = group,
            pattern = 'python',
            callback = function(ev)
                set(ev.buf)
            end,
        })
        -- command-line python buffers may already have FileType before init runs
        if vim.bo.filetype == 'python' then
            set(0)
        end
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
        ---@diagnostic disable-next-line: call-non-callable
        local adapter = require('neotest-python')(opts)
        adapter.name = 'Python'
        require('conf.neotest.adapters').attach(adapter)
    end,
}
