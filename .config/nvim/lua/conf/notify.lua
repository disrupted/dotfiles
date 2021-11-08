local M = {}

function M.setup()
    -- TODO: lazy load module when calling vim.notify
    -- local lazy_require = require('utils').lazy_require
    -- vim.notify = lazy_require 'notify'
end

function M.config()
    local notify = require 'notify'
    notify.setup { stages = 'static' }
    vim.notify = notify
end

return M
