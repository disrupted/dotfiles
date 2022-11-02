local M = {}

function M.setup()
    vim.keymap.set('n', '<leader>tf', function()
        require('neotest').run.run() -- test nearest function
    end)
    vim.keymap.set('n', '<leader>tb', function()
        require('neotest').run.run(vim.fn.expand '%') -- test entire file/buffer
    end)
    vim.keymap.set('n', '<leader>tl', function()
        require('neotest').run.run_last() -- re-run the last test
    end)
    vim.keymap.set('n', '<leader>to', function()
        require('neotest').output.open { last_run = true } -- open output of last test run
    end)
    vim.keymap.set('n', '<leader>td', function()
        require('neotest').run.run { strategy = 'dap' } -- debug nearest function
    end)
end

function M.config()
    require('neotest').setup {
        adapters = {
            require 'neotest-python' {
                dap = { justMyCode = false },
                runner = 'pytest',
                args = {
                    '--log-level',
                    'DEBUG',
                    '-vv',
                    -- '--color=no',
                },
            },
            require 'neotest-rust',
        },
    }
end

return M
