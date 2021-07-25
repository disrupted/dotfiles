local M = {}

function M.config()
    require('tabout').setup {
        tabkey = '<Tab>',
        act_as_tab = false,
        completion = true,
        tabouts = {
            { open = '\'', close = '\'' },
            { open = '"', close = '"' },
            { open = '`', close = '`' },
            { open = '(', close = ')' },
            { open = '[', close = ']' },
            { open = '{', close = '}' },
        },
        ignore_beginning = true,
        exclude = {},
    }
end
return M
