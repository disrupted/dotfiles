local M = {}

function M.config()
    vim.g.surround_mappings_style = 'surround'
    vim.g.surround_pairs = {
        nestable = { { '(', ')' }, { '[', ']' }, { '{', '}' }, { '<', '>' } },
        linear = { { '\'', '\'' }, { '"', '"' }, { '`', '`' } },
    }
    vim.g.surround_brackets = { '(', '{', '[', '<' }
    require('surround').setup {}
end

return M
