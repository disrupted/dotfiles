local M = {}

function M.setup()
    vim.keymap.set('n', ';;', function()
        require('harpoon.ui').toggle_quick_menu()
    end)
    vim.keymap.set('n', 'M', function()
        require('harpoon.mark').toggle_file()
    end)
    vim.keymap.set('n', ';a', function()
        require('harpoon.ui').nav_file(1)
    end)
    vim.keymap.set('n', ';s', function()
        require('harpoon.ui').nav_file(2)
    end)
    vim.keymap.set('n', ';d', function()
        require('harpoon.ui').nav_file(3)
    end)
    vim.keymap.set('n', ';f', function()
        require('harpoon.ui').nav_file(4)
    end)
    vim.keymap.set('n', ';g', function()
        require('harpoon.ui').nav_file(5)
    end)
end

function M.config()
    require('harpoon').setup {}
end

return M
