return {
    {
        'L3MON4D3/LuaSnip',
        lazy = true,
        config = function()
            local ls = require 'luasnip'
            local types = require 'luasnip.util.types'

            vim.api.nvim_set_hl(
                0,
                'LuasnipChoiceNodePassive',
                { italic = true }
            )
            vim.api.nvim_set_hl(0, 'LuasnipChoiceNodeActive', { bold = true })

            ls.config.set_config {
                keep_roots = true,
                link_roots = true,
                link_children = true,
                region_check_events = 'CursorMoved,CursorHold,InsertEnter',
                delete_check_events = 'InsertLeave',
                ext_opts = {
                    [types.choiceNode] = {
                        active = {
                            virt_text = { { '', 'Operator' } }, -- 
                            hl_mode = 'combine',
                        },
                    },
                    [types.insertNode] = {
                        active = {
                            virt_text = { { '', 'Type' } }, -- 
                            hl_mode = 'combine',
                        },
                    },
                },
                enable_autosnippets = true,
            }

            local function next_choice()
                if ls.choice_active() then
                    ls.change_choice(1)
                end
            end
            local opts = { silent = true }
            vim.keymap.set('i', '<C-e>', next_choice, opts)
            vim.keymap.set('s', '<C-e>', next_choice, opts)

            vim.api.nvim_create_autocmd('User', {
                pattern = 'LuasnipSnippetsAdded',
                callback = function()
                    print 'snippets loaded'
                end,
            })

            require('luasnip.loaders.from_lua').lazy_load { paths = './snippets' }
        end,
        dependencies = {
            'rafamadriz/friendly-snippets',
            config = function()
                require('luasnip.loaders.from_vscode').lazy_load()
            end,
            enabled = false,
        },
    },
    {
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        opts = function()
            local lsp = {
                kinds = {
                    Text = '',
                    Method = '',
                    Function = '',
                    Constructor = '',
                    Field = 'ﰠ',
                    Variable = '',
                    Class = 'ﴯ',
                    Interface = '',
                    Module = '',
                    Property = 'ﰠ',
                    Unit = '塞',
                    Value = '',
                    Enum = '',
                    Keyword = '',
                    Snippet = '',
                    Color = '',
                    File = '',
                    Reference = '',
                    Folder = '',
                    EnumMember = '',
                    Constant = '',
                    Struct = 'פּ',
                    Event = '',
                    Operator = '',
                    TypeParameter = '',
                },
            }
            local menu = {
                luasnip = '[snip]',
                nvim_lsp = '[LSP]',
                git = '[git]',
                nvim_lua = '[API]',
                spell = '[spell]',
                path = '[path]',
                buffer = '[buf]',
            }

            local cmp = require 'cmp'

            local lazy_require = require('utils').lazy_require
            local luasnip = lazy_require 'luasnip'

            -- supertab-like mapping
            local mapping = {
                ['<Tab>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item()
                    elseif luasnip and luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    else
                        fallback()
                    end
                end, { 'i', 's' }),
                ['<S-Tab>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    elseif luasnip and luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { 'i', 's' }),
                ['<C-n>'] = cmp.mapping.select_next_item {
                    behavior = cmp.SelectBehavior.Insert,
                },
                ['<C-p>'] = cmp.mapping.select_prev_item {
                    behavior = cmp.SelectBehavior.Insert,
                },
                ['<CR>'] = cmp.mapping.confirm {
                    behavior = cmp.ConfirmBehavior.Replace,
                    select = false,
                },
                ['<C-d>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<C-c>'] = cmp.mapping.complete {
                    config = {
                        sources = {
                            { name = 'nvim_lsp' },
                        },
                    },
                },
                ['<C-e>'] = cmp.mapping.close(),
                ['<Up>'] = cmp.config.disable,
                ['<Down>'] = cmp.config.disable,
            }

            return {
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body)
                    end,
                },
                mapping = mapping,
                sources = cmp.config.sources({
                    -- { name = 'nvim_lsp' },
                    {
                        name = 'nvim_lsp',
                        entry_filter = function(entry, ctx)
                            return require('cmp.types').lsp.CompletionItemKind[entry:get_kind()]
                                ~= 'Snippet'
                        end,
                    },
                    { name = 'luasnip' },
                    { name = 'git' },
                    -- { name = 'nvim_lua' },
                }, {
                    -- { name = 'spell' },
                    { name = 'buffer', keyword_length = 4 },
                    { name = 'path' },
                }),
                sorting = {
                    comparators = {
                        cmp.config.compare.offset,
                        cmp.config.compare.exact,
                        cmp.config.compare.score,
                        -- function(entry1, entry2)
                        --     local entry1_kind = require('cmp.types').lsp.CompletionItemKind[entry1:get_kind()]
                        --         == 'Snippet'
                        --     local entry2_kind = require('cmp.types').lsp.CompletionItemKind[entry2:get_kind()]
                        --         == 'Snippet'
                        --     print(entry1_kind)
                        --     print(entry2_kind)
                        --     -- if entry1_kind and not entry2_kind then
                        --     --     return false
                        --     -- else
                        --     --     return true
                        --     -- end
                        --     return true
                        -- end,
                        cmp.config.compare.kind,
                        cmp.config.compare.sort_text,
                        cmp.config.compare.length,
                        cmp.config.compare.order,
                    },
                },
                formatting = {
                    format = function(entry, vim_item)
                        -- source name
                        vim_item.menu = menu[entry.source.name]
                        -- lsp kinds
                        vim_item.kind = string.format(
                            '%s [%s]',
                            lsp.kinds[vim_item.kind],
                            vim_item.kind:lower()
                        )
                        -- shorten long items
                        vim_item.abbr = vim_item.abbr:sub(1, 30)
                        return vim_item
                    end,
                },
                experimental = { ghost_text = true },
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
                        'markdown', -- for gh cli
                    },
                },
            },
        },
    },
}
