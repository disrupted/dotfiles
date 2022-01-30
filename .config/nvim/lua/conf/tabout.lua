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
            { open = '#', close = ']' }, -- Rust macros
            { open = '<', close = '>' }, -- Java type annotation
        },
        ignore_beginning = true,
    }
end

return M
