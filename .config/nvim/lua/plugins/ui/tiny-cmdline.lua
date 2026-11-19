---@type doze.Spec
return {
    src = 'https://github.com/rachartier/tiny-cmdline.nvim',
    event = 'UIEnter',
    config = function()
        require('tiny-cmdline').setup()
    end,
}
