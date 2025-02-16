---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'numToStr/Navigator.nvim',
        cond = os.getenv 'TMUX' ~= vim.NIL,
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
        opts = { auto_save = 'all', disable_on_zoom = false },
    },
    {
        'folke/flash.nvim',
        ---@module 'flash.config'
        ---@type Flash.Config
        opts = {},
        keys = {
            {
                's',
                mode = { 'n', 'o' },
                function()
                    require('flash').jump()
                end,
                desc = 'Flash',
            },
            {
                'S',
                mode = { 'n', 'x', 'o' },
                function()
                    require('flash').treesitter()
                end,
                desc = 'Flash Treesitter',
            },
            {
                'r',
                mode = 'o',
                function()
                    require('flash').remote()
                end,
                desc = 'Remote Flash',
            },
            {
                'R',
                mode = { 'o', 'x' },
                function()
                    require('flash').treesitter_search()
                end,
                desc = 'Treesitter Search',
            },
            {
                '<c-s>',
                mode = { 'c' },
                function()
                    require('flash').toggle()
                end,
                desc = 'Toggle Flash Search',
            },
        },
    },
    {
        -- move through camelCase, snake_case words better
        'chrisgrieser/nvim-spider',
        keys = {
            {
                'w',
                function()
                    require('spider').motion 'w'
                end,
                desc = 'Spider-w',
                -- might have to use Ex commands for dot-repeat to work
                -- '<cmd>lua require(\'spider\').motion(\'w\')<CR>',
                mode = { 'n', 'o', 'x' },
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
            skipInsignificantPunctuation = false,
        },
    },
    {
        'aaronik/treewalker.nvim',
        cmd = 'Treewalker',
        keys = {
            {
                '<up>',
                function()
                    require('treewalker').move_up()
                end,
                desc = 'Up to prev neighbor node',
            },
            {
                '<down>',
                function()
                    require('treewalker').move_down()
                end,
                desc = 'Down to next neighbor node',
            },
            {
                '<left>',
                function()
                    require('treewalker').move_out()
                end,
                desc = 'Prev good child node',
            },
            {
                '<right>',
                function()
                    require('treewalker').move_in()
                end,
                desc = 'Next good child node',
            },
        },
        opts = {},
    },
}
