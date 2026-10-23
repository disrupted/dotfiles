---@type LazeSpec
return {
    'aaronik/treewalker.nvim',
    main = 'treewalker',
    module = 'treewalker',
    cmd = 'Treewalker',
    keys = {
        {
            '<Up>',
            function()
                require('treewalker').move_up()
            end,
            desc = 'Up to prev neighbor node',
        },
        {
            '<Down>',
            function()
                require('treewalker').move_down()
            end,
            desc = 'Down to next neighbor node',
        },
        {
            '<Left>',
            function()
                require('treewalker').move_out()
            end,
            desc = 'Prev good child node',
        },
        {
            '<Right>',
            function()
                require('treewalker').move_in()
            end,
            desc = 'Next good child node',
        },
        {
            '<M-k>',
            function()
                require('treewalker').move_up()
            end,
            desc = 'Up to prev neighbor node',
        },
        {
            '<M-j>',
            function()
                require('treewalker').move_down()
            end,
            desc = 'Down to next neighbor node',
        },
        {
            '<M-h>',
            function()
                require('treewalker').move_out()
            end,
            desc = 'Prev good child node',
        },
        {
            '<M-l>',
            function()
                require('treewalker').move_in()
            end,
            desc = 'Next good child node',
        },
        {
            '<C-M-k>',
            function()
                require('treewalker').swap_up()
            end,
            desc = 'Treewalker swap up',
        },
        {
            '<C-M-j>',
            function()
                require('treewalker').swap_down()
            end,
            desc = 'Treewalker swap down',
        },
        {
            '<C-M-h>',
            function()
                require('treewalker').swap_left()
            end,
            desc = 'Treewalker swap left',
        },
        {
            '<C-M-l>',
            function()
                require('treewalker').swap_right()
            end,
            desc = 'Treewalker swap right',
        },
    },
    opts = {},
}
