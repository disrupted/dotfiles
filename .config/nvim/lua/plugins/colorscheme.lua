return {
    {
        'disrupted/one.nvim', -- personal tweaked colorscheme
        lazy = false,
        priority = 1000,
        config = function()
            require('one').colorscheme()

            vim.keymap.set('n', '<M-t>', function()
                vim.o.background = (vim.o.background == 'light') and 'dark'
                    or 'light'
            end, {
                noremap = true,
                silent = true,
                desc = 'Toggle background between light and dark mode',
            })
        end,
    },
    {
        'catppuccin/nvim',
        enabled = false,
        name = 'catppuccin',
        priority = 1000,
        opts = {},
        config = function()
            vim.cmd.colorscheme 'catppuccin-mocha'
        end,
    },
}
