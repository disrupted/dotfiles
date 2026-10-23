---@type LazeSpec
return {
    'abecodes/tabout.nvim',
    main = 'tabout',
    module = 'tabout',
    event = 'InsertEnter',
    ---@module 'tabout.config'
    ---@type TaboutOptions
    opts = {
        completion = false,
        tabouts = {
            { open = '\'', close = '\'' },
            { open = '"', close = '"' },
            { open = '`', close = '`' },
            { open = '(', close = ')' },
            { open = '[', close = ']' },
            { open = '{', close = '}' },
            { open = '#', close = ']' }, -- Rust macros
            { open = '<', close = '>' }, -- Java type annotation
        },
        ignore_beginning = true,
    },
}
