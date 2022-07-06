local M = {}

function M.setup()
    vim.keymap.set('n', '<Space>tf', require('neotest').run.run) -- test nearest function
    vim.keymap.set('n', '<Space>tb', function()
        require('neotest').run.run(vim.fn.expand '%') -- test entire file/buffer
    end)
    vim.keymap.set('n', '<Space>td', function()
        require('neotest').run.run { strategy = 'dap' } -- debug nearest function
    end)
end

function M.config()
    require('neotest').setup {
        adapters = {
            require 'neotest-python' {
                dap = { justMyCode = false },
            },
        },
    }
end

return M