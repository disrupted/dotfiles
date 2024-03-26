return {
    {
        'disrupted/one.nvim', -- personal tweaked colorscheme
        lazy = false,
        priority = 9999,
        config = function()
            require('one').colorscheme()
        end,
    },
}
