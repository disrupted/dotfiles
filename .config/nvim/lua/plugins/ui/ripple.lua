---@type LazeSpec
return { -- inituitive window splits resizing
    'ian-howell/ripple.nvim',
    main = 'ripple',
    module = 'ripple',
    keys = {
        {
            '<C-S-k>',
            function()
                require('ripple').expand_up()
            end,
            mode = { 'n', 'v' },
            desc = 'Expand window up',
        },
        {
            '<C-S-j>',
            function()
                require('ripple').expand_down()
            end,
            mode = { 'n', 'v' },
            desc = 'Expand window down',
        },
        {
            '<C-S-h>',
            function()
                require('ripple').expand_left()
            end,
            mode = { 'n', 'v' },
            desc = 'Expand window left',
        },
        {
            '<C-S-l>',
            function()
                require('ripple').expand_right()
            end,
            mode = { 'n', 'v' },
            desc = 'Expand window right',
        },
    },
    opts = {
        disable_keymaps = true,
        vertical_step_size = 2,
        horizontal_step_size = 2,
    },
}
