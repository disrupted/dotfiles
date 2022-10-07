local M = {}

function M.config()
    require('noice').setup {
        -- classic cmdline
        -- cmdline = {
        --     view = 'cmdline',
        -- },
        routes = {
            {
                filter = {
                    event = 'cmdline',
                    find = '^%s*[/?]',
                },
                view = 'cmdline',
            },
        },
    }
end

return M
