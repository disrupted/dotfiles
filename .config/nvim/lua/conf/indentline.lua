local M = {}

function M.config()
    if vim.wo.colorcolumn == '' then
        vim.opt.colorcolumn = '99999' --  workaround for cursorline causing artifacts
    end

    require('indent_blankline').setup {
        char = '▏',
        context_char = '▏',
        show_first_indent_level = false,
        filetype_exclude = {
            'help',
            'markdown',
            'gitcommit',
            'packer',
        },
        buftype_exclude = { 'terminal', 'nofile' },
        use_treesitter = true,
        -- show_current_context = true,
        -- context_patterns = {
        --     'class',
        --     'function',
        --     'method',
        --     '^if',
        --     '^while',
        --     '^for',
        --     '^object',
        --     '^table',
        --     'block',
        --     'arguments',
        -- },
    }

    -- vim.cmd 'highlight! link IndentBlanklineContextChar Comment'
end

return M
