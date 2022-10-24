local M = {}

function M.setup()
    vim.keymap.set('n', '<leader>tf', function()
        require('neotest').run.run() -- test nearest function
    end)
    vim.keymap.set('n', '<leader>tb', function()
        require('neotest').run.run(vim.fn.expand '%') -- test entire file/buffer
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
                args = { '--log-level', 'DEBUG', '-vv' },
            },
        },
    }
end

return M
