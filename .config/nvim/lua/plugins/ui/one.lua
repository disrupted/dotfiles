---@type LazeSpec
return {
    'disrupted/one.nvim', -- personal tweaked colorscheme
    lazy = false,
    priority = 1000,
    config = function()
        require('one').setup()
    end,
}
