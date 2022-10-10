local M = {}

function M.config()
    require('noice').setup {
        cmdline = {
            icons = {
                [':'] = {
                    icon = '',
                    hl_group = 'DiagnosticInfo',
                    firstc = true,
                },
            },
        },
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
