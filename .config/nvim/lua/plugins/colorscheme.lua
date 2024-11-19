return {
    {
        'disrupted/one.nvim', -- personal tweaked colorscheme
        lazy = false,
        priority = 9999,
        config = function()
            require('one').colorscheme()

            vim.keymap.set(
                'n',
                '<M-t>',
                function()
                    vim.o.background = (vim.o.background == 'light') and 'dark'
                        or 'light'
                end,
                {
                    noremap = true,
                    silent = true,
                    desc = 'Toggle background between light and dark mode',
                }
            )
        end,
    },
}
