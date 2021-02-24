local M = {}

function M.config()
    vim.g.indent_blankline_char = '│'
    vim.g.indent_blankline_show_first_indent_level = false
    vim.g.indent_blankline_char_highlight = 'Whitespace'
end

return M
