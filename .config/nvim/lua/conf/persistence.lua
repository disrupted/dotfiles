local M = {}

function M.setup()
    vim.keymap.set('n', '<space>R', function()
        require('persistence').load()
    end)
end

function M.config()
    require('persistence').setup()
end

return M
