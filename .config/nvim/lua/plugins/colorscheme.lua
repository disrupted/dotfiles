---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'disrupted/one.nvim', -- personal tweaked colorscheme
        lazy = false,
        priority = 1000,
        keys = {
            {
                '<M-t>',
                function()
                    vim.o.background = (vim.o.background == 'light') and 'dark'
                        or 'light'
                end,
                desc = 'Toggle background between light and dark mode',
            },
        },
        config = true,
    },
}
