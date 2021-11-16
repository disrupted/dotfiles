local M = {}

function M.setup()
    -- TODO: lazy load module when calling vim.notify
    -- local lazy_require = require('utils').lazy_require
    -- vim.notify = lazy_require 'notify'
end

function M.config()
    local notify = require 'notify'

    notify.setup {
        stages = 'static',
        render = 'minimal',
        minimum_width = 10,
    }

    vim.notify = notify

    vim.cmd [[
        hi NotifyINFOBorder guifg=#80ff95
        hi link NotifyINFOBody NotifyINFOBorder
        hi NotifyWARNBorder guifg=#fff454
        hi link NotifyWARNBody NotifyWARNBorder
        hi NotifyERRORBorder guifg=#c44323
        hi link NotifyERRORBody NotifyERRORBorder
    ]]
end

return M
