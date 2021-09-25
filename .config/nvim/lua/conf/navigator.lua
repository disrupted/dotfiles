local M = {}

function M.setup()
    if os.getenv 'TMUX' then
        local map = require('utils').map
        map('n', '<C-w>j', '<cmd>lua require("Navigator").down()<CR>')
        map('n', '<C-w>k', '<cmd>lua require("Navigator").up()<CR>')
        map('n', '<C-w>h', '<cmd>lua require("Navigator").left()<CR>')
        map('n', '<C-w>l', '<cmd>lua require("Navigator").right()<CR>')
    end
end

function M.config()
    require('Navigator').setup { auto_save = 'all', disable_on_zoom = false }
end

return M
