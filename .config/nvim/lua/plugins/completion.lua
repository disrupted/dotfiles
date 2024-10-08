return {
    {
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        opts = function()
            local lsp = {
                kinds = {
                    Text = '󰉿',
                    Method = '',
                    Function = '󰊕',
                    Constructor = '',
                    Field = '󰜢',
                    Variable = '󰀫',
                    Class = '󰠱',
                    Interface = '󰒪',
                    Module = '',
                    Property = '󰜣',
                    Unit = '',
                    Value = '󰎠',
                    Enum = '',
                    Keyword = '󰌋',
                    Snippet = '',
                    Color = '󰏘',
                    File = '󰈙',
                    Reference = '󰋺',
                    Folder = '󰉋',
                    EnumMember = '',
                    Constant = '󰏿',
                    Struct = '󰙅',
                    Event = '',
                    Operator = '󰆕',
                    TypeParameter = '',
                },
            }
            local menu = {
                luasnip = '[snip]',
                nvim_lsp = '[LSP]',
                git = '[git]',
                spell = '[spell]',
                path = '[path]',
                buffer = '[buf]',
            }

            local cmp = require 'cmp'

            -- supertab-like mapping
            local mapping = {
                ['<C-n>'] = cmp.mapping.select_next_item {
                    behavior = cmp.SelectBehavior.Insert,
                },
                ['<C-p>'] = cmp.mapping.select_prev_item {
                    behavior = cmp.SelectBehavior.Insert,
                },
                ['<C-y>'] = cmp.mapping(
                    cmp.mapping.confirm {
                        behavior = cmp.SelectBehavior.Insert,
                        select = true,
                    },
                    { 'i', 'c' }
                ),
                ['<C-d>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-c>'] = cmp.mapping.complete {
                    config = {
                        sources = {
                            { name = 'nvim_lsp' },
                        },
                    },
                },
                ['<Up>'] = cmp.config.disable,
                ['<Down>'] = cmp.config.disable,
            }

            return {
                completion = {
                    autocomplete = {
                        cmp.TriggerEvent.TextChanged,
                        cmp.TriggerEvent.InsertEnter,
                    },
                },
                snippet = {
                    expand = function(args)
                        vim.snippet.expand(args.body)
                    end,
                },
                mapping = mapping,
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    -- {
                    --     name = 'nvim_lsp',
                    --     entry_filter = function(entry, ctx)
                    --         return require('cmp.types').lsp.CompletionItemKind[entry:get_kind()]
                    --             ~= 'Snippet'
                    --     end,
                    -- },
                    { name = 'luasnip' },
                    { name = 'git' },
                }, {
                    -- { name = 'spell' },
                    { name = 'buffer', keyword_length = 4 },
                    { name = 'path' },
                }),
                -- sorting = {
                --     comparators = {
                --         cmp.config.compare.offset,
                --         cmp.config.compare.exact,
                --         cmp.config.compare.score,
                --         -- function(entry1, entry2)
                --         --     local entry1_kind = require('cmp.types').lsp.CompletionItemKind[entry1:get_kind()]
                --         --         == 'Snippet'
                --         --     local entry2_kind = require('cmp.types').lsp.CompletionItemKind[entry2:get_kind()]
                --         --         == 'Snippet'
                --         --     print(entry1_kind)
                --         --     print(entry2_kind)
                --         --     -- if entry1_kind and not entry2_kind then
                --         --     --     return false
                --         --     -- else
                --         --     --     return true
                --         --     -- end
                --         --     return true
                --         -- end,
                --         -- cmp.config.compare.kind,
                --         cmp.config.compare.sort_text,
                --         cmp.config.compare.length,
                --         cmp.config.compare.order,
                --     },
                -- },
                formatting = {
                    format = function(entry, vim_item)
                        -- source name
                        vim_item.menu = menu[entry.source.name]
                        -- lsp kinds
                        if vim_item.kind ~= nil then
                            vim_item.kind = string.format(
                                '%s [%s]',
                                lsp.kinds[vim_item.kind],
                                vim_item.kind:lower()
                            )
                        end
                        -- shorten long items
                        vim_item.abbr = vim_item.abbr:sub(1, 30)
                        return vim_item
                    end,
                },
                -- experimental = { ghost_text = true },
            }
        end,
        dependencies = {
            'saadparwaiz1/cmp_luasnip',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'f3fora/cmp-spell',
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
    },
}
