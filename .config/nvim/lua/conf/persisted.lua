local M = {}

function M.setup()
    vim.keymap.set('n', '<space>R', function()
        require('persisted').load()
    end)
end

function M.config()
    require('persisted').setup()
end

return M
