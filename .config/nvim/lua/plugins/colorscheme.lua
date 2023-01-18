return {
    {
        'disrupted/one.nvim', -- personal tweaked colorscheme
        lazy = false,
        priority = 1000,
        config = function()
            -- vim.o.background = 'light'
            require('one').colorscheme()
        end,
    },
}
