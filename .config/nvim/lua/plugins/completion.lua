return {
    {
        'saghen/blink.cmp',
        lazy = false, -- lazy loading handled internally
        dependencies = {
            -- { 'rafamadriz/friendly-snippets' },
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
        ---@diagnostic disable: missing-fields
        opts = {
            keymap = {
                preset = 'default',
                ['<C-c>'] = {
                    'show',
                    'show_documentation',
                    'hide_documentation',
                },
                -- ['<C-s>'] = {
                --     function(cmp)
                --         cmp.show { providers = { 'luasnip' } }
                --     end,
                -- },
            },
            snippets = {
                expand = function(snippet)
                    require('luasnip').lsp_expand(snippet)
                end,
                active = function(filter)
                    if filter and filter.direction then
                        return require('luasnip').jumpable(filter.direction)
                    end
                    return require('luasnip').in_snippet()
                end,
                jump = function(direction)
                    require('luasnip').jump(direction)
                end,
            },
            sources = {
                completion = {
                    enabled_providers = {
                        'lsp',
                        'path',
                        'luasnip',
                        'buffer',
                        'git',
                        'lazydev',
                    },
                },
                providers = {
                    -- dont show LuaLS require statements when lazydev has items
                    lsp = {
                        timeout_ms = 400,
                        fallback_for = { 'lazydev' },
                    },
                    lazydev = {
                        name = 'LazyDev',
                        module = 'lazydev.integrations.blink',
                    },
                    git = {
                        name = 'git',
                        module = 'blink.compat.source',
                        score_offset = 3,
                        opts = {},
                    },
                },
            },
            trigger = { signature_help = { enabled = true } },
            highlight = {
                -- sets the fallback highlight groups to nvim-cmp's highlight groups
                -- useful for when your theme doesn't support blink.cmp
                -- will be removed in a future release, assuming themes add support
                use_nvim_cmp_as_default = true,
            },
            accept = { auto_brackets = { enabled = true } },
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
