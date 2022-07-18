local M = {}

function M.config()
    require('nvim-surround').setup {
        keymaps = {
            visual = 's',
        },
    }
end

return M
