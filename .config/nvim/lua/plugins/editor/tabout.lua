---@type doze.Spec
return {
    src = 'https://github.com/abecodes/tabout.nvim',
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
