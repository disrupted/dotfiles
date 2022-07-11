local M = {}

function M.setup()
    vim.keymap.set('n', '|', '<cmd>SymbolsOutline<CR>')
end

function M.config()
    require('symbols-outline').setup {
        show_guides = false,
        auto_preview = false,
        preview_bg_highlight = 'Normal',
        symbols = {
            File = { icon = '', hl = 'TSURI' },
            Module = { icon = '', hl = 'TSNamespace' },
            Namespace = { icon = '', hl = 'TSNamespace' },
            Package = { icon = '', hl = 'TSNamespace' },
            Class = { icon = 'ﴯ', hl = 'TSType' },
            Method = { icon = '', hl = 'TSMethod' },
            Property = { icon = 'ﰠ', hl = 'TSMethod' },
            Field = { icon = 'ﰠ', hl = 'TSField' },
            Constructor = { icon = '', hl = 'TSConstructor' },
            Enum = { icon = '', hl = 'TSType' },
            Interface = { icon = '', hl = 'TSType' },
            Function = { icon = '', hl = 'TSFunction' },
            Variable = { icon = '', hl = 'TSConstant' },
            Constant = { icon = '', hl = 'TSConstant' },
            String = { icon = '', hl = 'TSString' },
            Number = { icon = '', hl = 'TSNumber' },
            Boolean = { icon = '⊨', hl = 'TSBoolean' },
            Array = { icon = '', hl = 'TSConstant' },
            Object = { icon = '⦿', hl = 'TSType' },
            Key = { icon = '', hl = 'TSType' },
            Null = { icon = 'NULL', hl = 'TSType' },
            EnumMember = { icon = '', hl = 'TSField' },
            Struct = { icon = 'פּ', hl = 'TSType' },
            Event = { icon = '', hl = 'TSType' },
            Operator = { icon = '', hl = 'TSOperator' },
            TypeParameter = { icon = '', hl = 'TSParameter' },
        },
    }
    vim.api.nvim_set_hl(0, 'FocusedSymbol', { link = 'CursorLine' })
end

return M
