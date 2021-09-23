local M = {}

function M.config()
    local npairs = require 'nvim-autopairs'
    npairs.setup { check_ts = true }

    local Rule = require 'nvim-autopairs.rule'
    npairs.add_rule(Rule('<', '>'))

    -- cmp integration
    require('nvim-autopairs.completion.cmp').setup {
        map_cr = true,
        map_complete = true,
        auto_select = false,
        insert = false,
        map_char = {
            all = '(',
            tex = '{',
        },
    }
end

return M
