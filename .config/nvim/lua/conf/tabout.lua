local M = {}

function M.config()
    require('tabout').setup {
        completion = false,
        tabouts = {
            { open = '\'', close = '\'' },
            { open = '"', close = '"' },
            { open = '`', close = '`' },
            { open = '(', close = ')' },
            { open = '[', close = ']' },
            { open = '{', close = '}' },
            { open = '#', close = ']' },
        },
        ignore_beginning = true,
    }
end

return M
