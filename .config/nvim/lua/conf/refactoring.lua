local M = {}

function M.setup()
    vim.keymap.set('v', '<leader>rr', function()
        require('refactoring').select_refactor()
    end)
    vim.keymap.set('v', '<leader>re', function()
        require('refactoring').refactor 'Extract Function'
    end)
end

function M.config()
    require('refactoring').setup()
end

return M
