---@type LazeSpec[]
return {
    {
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
    },
    {
        -- move through camelCase, snake_case words better
        'chrisgrieser/nvim-spider',
        main = 'spider',
        module = 'spider',
        keys = {
            {
                'w',
                function()
                    require('spider').motion 'w'
                end,
                desc = 'Spider-w',
                -- NOTE: might have to use Ex commands for dot-repeat to work
                -- '<cmd>lua require(\'spider\').motion(\'w\')<CR>',
                mode = { 'n' },
            },
            {
                'w',
                function()
                    require('spider').motion(
                        'w',
                        { skipInsignificantPunctuation = false }
                    )
                end,
                desc = 'Spider-w',
                mode = { 'o', 'x' },
            },
            {
                'e',
                function()
                    require('spider').motion 'e'
                end,
                desc = 'Spider-e',
                mode = { 'n', 'o', 'x' },
            },
            {
                'b',
                function()
                    require('spider').motion 'b'
                end,
                desc = 'Spider-b',
                mode = { 'n', 'o', 'x' },
            },
            {
                'ge',
                function()
                    require('spider').motion 'ge'
                end,
                desc = 'Spider-ge',
                mode = { 'n', 'o', 'x' },
            },
        },
        opts = {
            skipInsignificantPunctuation = true,
        },
    },
    {
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
    },
}
