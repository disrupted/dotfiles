local M = {}

function M.setup()
    vim.keymap.set('v', '<leader>rr', require('refactoring').select_refactor)
    vim.keymap.set('v', '<leader>re', function()
        require('refactoring').refactor 'Extract Function'
    end)
end

function M.config()
    require('refactoring').setup()
end

return M
