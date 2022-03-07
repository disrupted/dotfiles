local M = {}

function M.setup()
    vim.keymap.set('n', '<space>g', function()
        require('neogit').open()
    end)
    vim.keymap.set('n', '<space>c', function()
        require('neogit').open { 'commit' }
    end)
end

function M.config()
    require('neogit').setup {
        signs = {
            section = { '', '' },
            item = { '', '' },
            hunk = { '', '' },
        },
        integrations = {
            diffview = true,
        },
    }
end

return M
