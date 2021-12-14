local M = {}

function M.config()
    require('tabout').setup {
        -- act_as_tab = false,
        completion = false,
        tabouts = {
            { open = '\'', close = '\'' },
            { open = '"', close = '"' },
            { open = '`', close = '`' },
            { open = '(', close = ')' },
            { open = '[', close = ']' },
            { open = '{', close = '}' },
        },
        -- ignore_beginning = true,
        -- exclude = {},
    }
end

return M
