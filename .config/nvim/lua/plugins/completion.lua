---@type LazySpec[]
return {
    {
        'saghen/blink.cmp',
        -- lazy = false, -- lazy loading handled internally
        event = { 'InsertEnter', 'CmdlineEnter' },
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
        -- HACK: use main temporarily because of Luasnip duplicate snippets fix https://github.com/Saghen/blink.cmp/commit/f0f34c318af019b44fc8ea347895dcf92b682122
        -- version = '*',
        build = 'cargo build --release',
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
            keymap = {
                preset = 'default',
                ['<C-c>'] = {
                    'show',
                    'cancel',
                },
                ['<C-d>'] = {
                    'show_documentation',
                    'hide_documentation',
                },
                ['<C-e>'] = {}, -- disable default because mapped to LuaSnip
                ['<C-s>'] = {
                    function(cmp)
                        cmp.show { providers = { 'snippets' } }
                    end,
                },
            },
            snippets = { preset = 'luasnip' },
            completion = {
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 200,
                },
                ghost_text = {
                    enabled = true,
                    show_without_selection = true,
                },
                menu = {
                    draw = {
                        treesitter = { 'lsp' },
                        columns = function(ctx)
                            if ctx.mode == 'cmdline' then
                                return { { 'label' } }
                            else
                                return {
                                    { 'kind_icon' },
                                    { 'label', 'label_description', gap = 1 },
                                    { 'source_icon' },
                                }
                            end
                        end,
                        components = {
                            source_icon = {
                                width = { fixed = 1 },
                                ellipsis = false,
                                text = function(ctx)
                                    return require('conf.icons').cmp_sources[ctx.source_name]
                                end,
                                highlight = 'BlinkCmpSource',
                            },
                        },
                    },
                },
            },
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
                    lazydev = {
                        name = 'LazyDev',
                        module = 'lazydev.integrations.blink',
                        -- make lazydev completions top priority
                        score_offset = 100,
                    },
                    git = {
                        name = 'git',
                        module = 'blink.compat.source',
                        score_offset = 10,
                        opts = {},
                    },
                    snippets = {
                        min_keyword_length = 2,
                        score_offset = 6,
                    },
                    lsp = {
                        score_offset = 5,
                        timeout_ms = 400,
                    },
                    path = {
                        min_keyword_length = 3,
                        opts = {
                            get_cwd = function(_)
                                return vim.uv.cwd()
                            end,
                        },
                    },
                    buffer = {
                        min_keyword_length = 5,
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
