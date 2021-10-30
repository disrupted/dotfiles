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
        cmp_git = '[Git]',
        nvim_lua = '[API]',
        spell = '[Spell]',
        path = '[Path]',
        buffer = '[Buf]',
    }

    local cmp = require 'cmp'

    local prequire = require('utils').prequire
    local luasnip = prequire 'luasnip'
    local tabout = prequire 'tabout'

    -- supertab-like mapping
    local mapping = {
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip and luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            elseif tabout then
                tabout.tabout()
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
            elseif tabout then
                tabout.taboutBack()
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
            select = true,
        },
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
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
        sources = {
            { name = 'luasnip' },
            { name = 'nvim_lsp' },
            { name = 'cmp_git' },
            { name = 'nvim_lua' },
            { name = 'spell' },
            { name = 'path' },
            { name = 'buffer', keyword_length = 5 },
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

    -- autopairs integration: insert () after selecting function or method item
    local lazy_require = require('utils').lazy_require
    cmp.event:on(
        'confirm_done',
        lazy_require('nvim-autopairs.completion.cmp').on_confirm_done()
    )
end

return M
