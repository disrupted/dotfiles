---@type doze.Spec
return {
    src = 'https://github.com/MagicDuck/grug-far.nvim',
    keys = {
        {
            '<C-_>', -- ctrl + /
            function()
                require('grug-far').toggle_instance({
                    transient = true,
                    startInInsertMode = false,
                })
            end,
            desc = 'Find and Replace',
        },
    },
    config = function()
        ---@type grug.far.OptionsOverride
        local opts = {
            keymaps = {
                nextInput = { n = '<C-n>', i = '<C-n>' },
                prevInput = { n = '<C-p>', i = '<C-p>' },
            },
        }
        require('grug-far').setup(opts)
    end,
}
