local M = {}

function M.setup()
    vim.keymap.set('n', '\'', function()
        require 'neoclip'
        require('telescope').extensions.neoclip.default()
    end)
end

function M.config()
    require('neoclip').setup()
end

return M
