local M = {}

function M.config()
    require('surround').setup {
        mappings_style = 'surround',
        brackets = { '(', '{', '[', '<' },
        pairs = {
            nestable = {
                { '(', ')' },
                { '[', ']' },
                { '{', '}' },
                { '<', '>' },
            },
            linear = { { '\'', '\'' }, { '"', '"' }, { '`', '`' } },
        },
    }
end

return M
