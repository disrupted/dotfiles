---@type doze.Spec
return {
    src = 'https://github.com/disrupted/one.nvim', -- personal tweaked colorscheme
    lazy = false,
    priority = 1000,
    config = function()
        require('one').setup()
    end,
}
