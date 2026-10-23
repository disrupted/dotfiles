---@type LazeSpec
return {
    'MagicDuck/grug-far.nvim',
    main = 'grug-far',
    module = 'grug-far',
    keys = {
        {
            '<C-_>', -- ctrl + /
            function()
                require('grug-far').toggle_instance {
                    transient = true,
                    startInInsertMode = false,
                }
            end,
            desc = 'Find and Replace',
        },
    },
    ---@module 'grug-far'
    ---@type grug.far.OptionsOverride
    opts = {
        keymaps = {
            nextInput = { n = '<C-n>', i = '<C-n>' },
            prevInput = { n = '<C-p>', i = '<C-p>' },
        },
    },
}
