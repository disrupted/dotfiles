local M = {}

function M.config()
    vim.opt.colorcolumn = '99999' --  workaround for cursorline causing artifacts
    vim.g.indent_blankline_char = '▏'
    vim.g.indent_blankline_show_first_indent_level = false
    vim.g.indent_blankline_filetype_exclude = {
        'help',
        'markdown',
        'gitcommit',
        'packer',
    }
    vim.g.indent_blankline_buftype_exclude = { 'terminal', 'nofile' }
    vim.g.indent_blankline_use_treesitter = true
    -- vim.g.indent_blankline_show_current_context = true
    -- vim.g.indent_blankline_context_patterns =
    --     {
    --         'class', 'function', 'method', '^if', '^while', '^for', '^object',
    --         '^table', 'block', 'arguments'
    --     }
end

return M
