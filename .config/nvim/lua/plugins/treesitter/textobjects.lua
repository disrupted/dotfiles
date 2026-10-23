---@type LazeSpec
return {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    main = 'nvim-treesitter-textobjects',
    module = 'nvim-treesitter-textobjects',
    keys = {
        {
            'af',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@function.outer',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Function outer',
        },
        {
            'if',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@function.inner',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Function inner',
        },
        {
            'aC',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@class.outer',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Class outer',
        },
        {
            'iC',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@class.inner',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Class inner',
        },
        {
            'ap',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@parameter.outer',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Parameter outer',
        },
        {
            'ip',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@parameter.inner',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Parameter inner',
        },
        {
            'ao',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@conditional.outer',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Conditional outer',
        },
        {
            'io',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@conditional.inner',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Conditional inner',
        },
        {
            'ab',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@block.outer',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Block outer',
        },
        {
            'ib',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@block.inner',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Block inner',
        },
        {
            'al',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@loop.outer',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Loop outer',
        },
        {
            'il',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@loop.inner',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Loop inner',
        },
        {
            'as',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@statement.outer',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Statement outer',
        },
        {
            'is',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@statement.inner',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Statement inner',
        },
        {
            'am',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@call.outer',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Call outer',
        },
        {
            'im',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@call.inner',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Call inner',
        },
        {
            'ac',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@comment.outer',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Comment outer',
        },
        {
            'ic',
            function()
                require('nvim-treesitter-textobjects.select').select_textobject(
                    '@comment.inner',
                    'textobjects'
                )
            end,
            mode = { 'x', 'o' },
            desc = 'Comment inner',
        },
        {
            ']f',
            function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
                    '@function.outer',
                    'textobjects'
                )
            end,
            mode = { 'n', 'x', 'o' },
            desc = 'Next function',
        },
        {
            '[f',
            function()
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@function.outer',
                    'textobjects'
                )
            end,
            mode = { 'n', 'x', 'o' },
            desc = 'Prev function',
        },
        {
            ']C',
            function()
                require('nvim-treesitter-textobjects.move').goto_next_start(
                    '@class.outer',
                    'textobjects'
                )
            end,
            mode = { 'n', 'x', 'o' },
            desc = 'Next class',
        },
        {
            '[C',
            function()
                require('nvim-treesitter-textobjects.move').goto_previous_start(
                    '@class.outer',
                    'textobjects'
                )
            end,
            mode = { 'n', 'x', 'o' },
            desc = 'Prev class',
        },
    },
    config = function()
        local opts = {
            select = {
                selection_modes = {
                    ['@function.outer'] = 'V', -- linewise
                    ['@class.outer'] = 'V', -- linewise
                },
            },
        }
        require('nvim-treesitter-textobjects').setup(opts)
    end,
}
