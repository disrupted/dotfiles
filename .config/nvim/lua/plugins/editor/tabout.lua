---@type doze.Spec
return {
    src = 'https://github.com/abecodes/tabout.nvim',
    event = 'InsertEnter',
    config = function()
        ---@type Partial<TaboutOptions>
        local opts = {
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
        }
        require('tabout').setup(opts --[[@as TaboutOptions]])
    end,
}
