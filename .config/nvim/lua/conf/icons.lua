return {
    cmp_sources = setmetatable({
        LSP = '',
        Snippets = '󰐱', -- 󰩫  󱡄 󰐱
        Buffer = '󰈙',
        Path = '󰉋',
        cmdline = '',
    }, {
        __index = function(table, key)
            return ''
        end,
    }),
    kinds = {
        Array = '󰅪',
        Boolean = '◩',
        Class = '󰙅',
        Color = '󰏘',
        Control = '',
        Collapsed = '',
        Constant = '󰏿',
        Constructor = '',
        Copilot = '',
        Enum = '',
        EnumMember = '',
        Event = '',
        Field = '󰜢',
        File = '󰈙',
        Folder = '󰉋',
        Function = '󰊕',
        Interface = '󰕘',
        Key = '󰌋',
        Keyword = '󰌋',
        Method = '',
        Module = '',
        Namespace = '󰌗',
        Null = '󰢤',
        Number = '󰎠',
        Object = '',
        Operator = '󰆕',
        Package = '󰆦',
        Property = '',
        Reference = '󰋺',
        Snippet = '󱡄',
        String = '󰉾',
        Struct = '󱡠',
        Text = '󰉿', -- 
        TypeParameter = '󰊄',
        Unit = '',
        Unknown = '?', -- 
        Value = '󰦨',
        Variable = '󰀫',
    },
}
