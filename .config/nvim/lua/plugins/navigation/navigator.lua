---@type doze.Spec
return {
    src = 'https://github.com/numToStr/Navigator.nvim',
    enabled = vim.env.REX_SESSION ~= nil,
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
        local opts = {
            auto_save = false,
            disable_on_zoom = false,
            mux = require('conf.navigator.rex'):new(),
        }
        ---@cast opts Config
        require('Navigator').setup(opts)
    end,
}
