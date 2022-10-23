local M = {}

function M.setup()
    vim.keymap.set('n', '<leader>R', function()
        require('persisted').load {}
    end)
end

function M.config()
    require('persisted').setup {}
end

return M
