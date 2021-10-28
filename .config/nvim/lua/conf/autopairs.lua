local M = {}

function M.config()
    local npairs = require 'nvim-autopairs'
    npairs.setup { check_ts = true }

    local Rule = require 'nvim-autopairs.rule'
    npairs.add_rule(Rule('<', '>'))
end

return M
