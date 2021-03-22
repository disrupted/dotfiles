local M = {}

function M.config()
    vim.g.indent_blankline_char = '│'
    vim.g.indent_blankline_show_first_indent_level = false
    vim.g.indent_blankline_char_highlight = 'Whitespace'
    vim.g.indent_blankline_filetype_exclude = {'help', 'markdown'}
    vim.g.indent_blankline_buftype_exclude = {'terminal', 'nofile', 'packer'}
end

return M
