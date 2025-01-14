return {
    {
        'saghen/blink.cmp',
        lazy = false, -- lazy loading handled internally
        dependencies = {
            {
                'saghen/blink.compat', -- compatibility layer with nvim-cmp sources
                version = '*',
                lazy = true,
                opts = {},
            },
            {
                'petertriho/cmp-git',
                opts = {
                    filetypes = {
                        'gitcommit',
                        'octo',
                        'markdown', -- for gh & glab CLI
                    },
                },
            },
        },
        version = 'v0.*',
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
            keymap = {
                preset = 'default',
                ['<C-c>'] = {
                    'show',
                    'show_documentation',
                    'hide_documentation',
                },
                ['<C-s>'] = {
                    function(cmp)
                        cmp.show { providers = { 'snippets' } }
                    end,
                },
            },
            snippets = { preset = 'luasnip' },
            sources = {
                default = {
                    'lazydev',
                    'lsp',
                    'path',
                    'snippets',
                    'buffer',
                    'git',
                },
                providers = {
                    lsp = {
                        timeout_ms = 400,
                    },
                    lazydev = {
                        name = 'LazyDev',
                        module = 'lazydev.integrations.blink',
                        -- make lazydev completions top priority
                        score_offset = 100,
                    },
                    git = {
                        name = 'git',
                        module = 'blink.compat.source',
                        score_offset = 3,
                        opts = {},
                    },
                },
            },
            signature = { enabled = true },
            appearance = {
                kind_icons = {
                    Text = '󰉿', -- 
                    Method = '',
                    Function = '󰊕',
                    Constructor = '',

                    Field = '󰜢',
                    Variable = '󰀫',
                    Property = '',

                    Class = '󰙅',
                    Interface = '󰕘',
                    Struct = '󱡠',
                    Module = '',

                    Unit = '',
                    Value = '󰦨', -- 󰎠
                    Enum = '',
                    EnumMember = '',

                    Keyword = '󰌋',
                    Constant = '󰏿',

                    Snippet = '󰩫', -- 󱄽
                    Color = '󰏘',
                    File = '󰈙',
                    Reference = '󰋺',
                    Folder = '󰉋',
                    Event = '',
                    Operator = '󰆕',
                    TypeParameter = '󰊄',
                },
            },
        },
    },
}
