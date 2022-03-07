local M = {}

function M.setup()
    if os.getenv 'TMUX' then
        vim.keymap.set('n', '<C-w>j', function()
            require('Navigator').down()
        end)
        vim.keymap.set('n', '<C-w>k', function()
            require('Navigator').up()
        end)
        vim.keymap.set('n', '<C-w>h', function()
            require('Navigator').left()
        end)
        vim.keymap.set('n', '<C-w>l', function()
            require('Navigator').right()
        end)
    end
end

function M.config()
    require('Navigator').setup { auto_save = 'all', disable_on_zoom = false }
end

return M
