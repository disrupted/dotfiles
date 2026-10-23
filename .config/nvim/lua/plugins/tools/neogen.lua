---@type LazeSpec
return {
    'danymat/neogen',
    main = 'neogen',
    module = 'neogen',
    cmd = 'Neogen',
    init = function()
        require('which-key').add {
            { '<Leader>D', group = 'Generate docs', icon = '󰦨' },
        }
    end,
    keys = {
        {
            '<Leader>Df',
            function()
                require('neogen').generate {}
            end,
            desc = 'Function',
        },
        {
            '<Leader>DC',
            function()
                require('neogen').generate { type = 'class' }
            end,
            desc = 'Class',
        },
    },
    opts = {
        snippet_engine = 'luasnip',
        languages = {
            python = {
                template = {
                    annotation_convention = 'reST',
                },
            },
            lua = {
                template = {
                    annotation_convention = 'emmylua',
                },
            },
        },
    },
}
