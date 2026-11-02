---@type LazeSpec
return {
    'numToStr/Navigator.nvim',
    module = 'Navigator',
    cond = vim.env.REX_SESSION ~= nil or vim.env.TMUX ~= nil,
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
    config = function()
        local opts = { auto_save = false, disable_on_zoom = false }
        if vim.env.REX_SESSION then
            opts.mux = require('conf.navigator.rex'):new()
        end
        ---@cast opts Config
        require('Navigator').setup(opts)
    end,
}
