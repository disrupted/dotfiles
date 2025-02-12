return {
    cmp_sources = setmetatable({
        LSP = '',
        Snippets = '󰩫',
        Buffer = '󰈙',
        Path = '󰉋',
        cmdline = '',
    }, {
        __index = function(table, key)
            return ''
        end,
    }),
}
