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
        'ggandor/lightspeed.nvim',
        enabled = false,
        lazy = true,
        keys = {
            -- { 's', mode = { 'n', 'x' } },
            -- { 'S', mode = { 'n', 'x' } },
            { 's', mode = 'n' },
            { 'S', mode = 'n' },
            { 'z', mode = 'o' },
            { 'Z', mode = 'o' },
            { 'x', mode = 'o' },
            { 'X', mode = 'o' },
            { 'f', mode = { 'n', 'x', 'o' } },
            { 'F', mode = { 'n', 'x', 'o' } },
        },
        opts = {
            ignore_case = true,
            exit_after_idle_msecs = { labeled = 4000, unlabeled = 3000 },
        },
    },
    {
        'ggandor/leap.nvim',
        enabled = false,
        event = 'VimEnter',
        config = function()
            require('leap').set_default_keymaps()
        end,
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
        'SmiteshP/nvim-navbuddy',
        keys = {
            {
                '<leader>n',
                function()
                    require('nvim-navbuddy').open()
                end,
            },
        },
        dependencies = {
            'SmiteshP/nvim-navic',
            'MunifTanjim/nui.nvim',
        },
        opts = {
            lsp = { auto_attach = true },
            icons = {
                Array = '󰅪 ',
                Boolean = '◩ ',
                Class = '󰙅 ',
                Constructor = ' ',
                Constant = '󰏿 ',
                Enum = ' ',
                EnumMember = ' ',
                Event = ' ',
                Field = '󰜢 ',
                File = '󰈙 ',
                Function = '󰊕 ',
                Interface = '󰕘 ',
                Key = '󰌋 ',
                Method = ' ',
                Module = ' ',
                Namespace = '󰌗 ',
                Null = '󰢤 ',
                Object = '󰅩 ',
                Operator = '󰆕 ',
                Package = '󰆦 ',
                Property = ' ',
                String = '󰉾 ',
                Struct = '󱡠 ',
                TypeParameter = '󰊄 ',
                Variable = '󰀫 ',
                Number = '󰎠 ',
            },
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
