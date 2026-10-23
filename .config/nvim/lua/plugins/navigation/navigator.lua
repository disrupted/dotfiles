---@type LazeSpec
return {
    'numToStr/Navigator.nvim',
    main = 'Navigator',
    module = 'Navigator',
    cond = vim.env.TMUX ~= nil,
    keys = {
        {
            '<C-w>j',
            function()
                require('Navigator').down()
            end,
        },
        {
            '<C-w>k',
            function()
                require('Navigator').up()
            end,
        },
        {
            '<C-w>h',
            function()
                require('Navigator').left()
            end,
        },
        {
            '<C-w>l',
            function()
                require('Navigator').right()
            end,
        },
    },
    opts = { auto_save = false, disable_on_zoom = false },
}
