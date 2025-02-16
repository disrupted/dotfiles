---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'saghen/blink.cmp',
        event = { 'InsertEnter', 'CmdlineEnter' },
        dependencies = {
            {
                'Kaiser-Yang/blink-cmp-git',
                dependencies = { 'nvim-lua/plenary.nvim' },
            },
        },
        version = '*',
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
            keymap = {
                preset = 'default',
                ['<C-c>'] = { 'show', 'cancel' },
                ['<C-d>'] = { 'show_documentation', 'hide_documentation' },
                ['<C-e>'] = {}, -- disable default because mapped to LuaSnip
                ['<C-s>'] = {
                    function(cmp)
                        cmp.show { providers = { 'snippets' } }
                    end,
                },
                ['<a-d>'] = {
                    -- inspect the current completion item for debugging
                    function()
                        local item =
                            require('blink.cmp.completion.list').get_selected_item()
                        vim.print(item)
                        return true
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
                    show_without_selection = false,
                },
                list = {
                    selection = {
                        preselect = function(ctx)
                            return ctx.mode ~= 'cmdline'
                        end,
                    },
                },
                menu = {
                    auto_show = function(ctx)
                        return ctx.mode ~= 'cmdline'
                            or not vim.tbl_contains(
                                { '/', '?' },
                                vim.fn.getcmdtype()
                            )
                    end,
                    draw = {
                        columns = function(ctx)
                            if ctx.mode == 'cmdline' then
                                return { { 'label' } }
                            else
                                return {
                                    { 'kind_icon' },
                                    {
                                        'label',
                                        'label_description',
                                        'space', -- HACK: try to right-align source_icon
                                        'source_icon',
                                        gap = 1,
                                    },
                                }
                            end
                        end,
                        components = {
                            label_description = {
                                width = {
                                    -- make component after it in the same group right-aligned
                                    -- FIXME: does not seem to work reliably
                                    fill = true,
                                },
                            },
                            source_icon = {
                                width = { fixed = 1 },
                                ellipsis = false,
                                text = function(ctx)
                                    return require('conf.icons').cmp_sources[ctx.source_name]
                                end,
                                highlight = 'BlinkCmpSource',
                            },
                            space = {
                                width = { fixed = 1, fill = true },
                                text = function()
                                    return ' '
                                end,
                            },
                        },
                    },
                },
            },
            sources = {
                default = function()
                    local success, node = pcall(vim.treesitter.get_node)
                    if
                        success
                        and node
                        and vim.tbl_contains(
                            { 'comment', 'line_comment', 'block_comment' },
                            node:type()
                        )
                    then
                        return { 'buffer' }
                    end
                    local sources = {
                        'lsp',
                        'path',
                        'snippets',
                        'buffer',
                        'git',
                    }
                    if vim.bo.filetype == 'lua' then
                        table.insert(sources, 'lazydev')
                    end
                    return sources
                end,
                providers = {
                    lazydev = {
                        name = 'LazyDev',
                        module = 'lazydev.integrations.blink',
                        -- make lazydev completions top priority
                        score_offset = 100,
                    },
                    git = {
                        module = 'blink-cmp-git',
                        name = 'Git',
                        score_offset = 10,
                        enabled = function()
                            return vim.tbl_contains(
                                { 'octo', 'gitcommit', 'markdown' },
                                vim.bo.filetype
                            )
                        end,
                        --- @module 'blink-cmp-git'
                        --- @type blink-cmp-git.Options
                        opts = {},
                    },
                    snippets = {
                        min_keyword_length = 2,
                        score_offset = 6,
                        should_show_items = function(ctx)
                            return ctx.trigger.initial_kind
                                ~= 'trigger_character' -- hide snippets after trigger character
                        end,
                    },
                    lsp = {
                        score_offset = 5,
                        timeout_ms = 400,
                    },
                    path = {
                        opts = {
                            get_cwd = function(_)
                                return vim.uv.cwd()
                            end,
                        },
                    },
                    buffer = {
                        min_keyword_length = 3,
                    },
                },
            },
            signature = { enabled = true },
            cmdline = {
                keymap = {
                    preset = 'enter',
                    ['<CR>'] = { 'accept_and_enter', 'fallback' },
                    ['<Up>'] = {},
                    ['<Down>'] = {},
                    ['<C-j>'] = {},
                    ['<C-k>'] = {},
                },
            },
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
