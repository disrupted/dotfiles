local M = {}

function M.config()
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
        luasnip = '[Snip]',
        nvim_lsp = '[LSP]',
        git = '[Git]',
        nvim_lua = '[API]',
        spell = '[Spell]',
        path = '[Path]',
        buffer = '[Buf]',
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
        end, {
            'i',
            's',
        }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip and luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, {
            'i',
            's',
        }),
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
        ['<C-c>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<Up>'] = cmp.config.disable,
        ['<Down>'] = cmp.config.disable,
    }

    cmp.setup {
        snippet = {
            expand = function(args)
                require('luasnip').lsp_expand(args.body)
            end,
        },
        mapping = mapping,
        sources = cmp.config.sources({
            { name = 'luasnip' },
            { name = 'nvim_lsp' },
            { name = 'git' },
            -- { name = 'nvim_lua' },
        }, {
            -- { name = 'spell' },
            { name = 'buffer', keyword_length = 4 },
            { name = 'path' },
        }),
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

    -- autopairs integration: insert () after selecting function or method item
    -- NOTE: disabled in favor of LSPs defining their own behavior
    --[[ cmp.event:on(
        'confirm_done',
        lazy_require('nvim-autopairs.completion.cmp').on_confirm_done {
            filetypes = {
                -- "*" is a alias to all filetypes
                ['*'] = {
                    ['('] = {
                        kind = {
                            cmp.lsp.CompletionItemKind.Function,
                            cmp.lsp.CompletionItemKind.Method,
                        },
                        handler = lazy_require(
                            'nvim-autopairs.completion.handlers'
                        )['*'],
                    },
                },
                lua = {
                    ['('] = {
                        kind = {
                            cmp.lsp.CompletionItemKind.Function,
                            cmp.lsp.CompletionItemKind.Method,
                        },
                        ---@param char string
                        ---@param item item completion
                        ---@param bufnr buffer number
                        handler = function(char, item, bufnr)
                            -- Your handler function. Inpect with print(vim.inspect{char, item, bufnr})
                        end,
                    },
                },
                -- Disable for tex
                tex = false,
            },
        }
    ) ]]
end

return M
