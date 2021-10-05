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

    local cmp = require 'cmp'

    local t = function(str)
        return vim.api.nvim_replace_termcodes(str, true, true, true)
    end

    local check_back_space = function()
        local col = vim.fn.col '.' - 1
        return col == 0 or vim.fn.getline('.'):sub(col, col):match '%s' ~= nil
    end

    local prequire = require('utils').prequire
    local luasnip = prequire 'luasnip'

    -- supertab-like mapping
    local mapping = {
        ['<Tab>'] = cmp.mapping(function(_)
            if vim.fn.pumvisible() == 1 then
                vim.fn.feedkeys(t '<C-n>', 'n')
            elseif luasnip and luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            elseif check_back_space() then
                vim.fn.feedkeys(t '<Tab>', 'n')
            else
                vim.fn.feedkeys(t '<Plug>(Tabout)', '')
            end
        end, {
            'i',
            's',
        }),
        ['<S-Tab>'] = cmp.mapping(function(_)
            if vim.fn.pumvisible() == 1 then
                vim.fn.feedkeys(t '<C-p>', 'n')
            elseif luasnip and luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                vim.fn.feedkeys(t '<Plug>(TaboutBack)', '')
            end
        end, {
            'i',
            's',
        }),
        ['<CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
        },
    }

    cmp.setup {
        snippet = {
            expand = function(args)
                require('luasnip').lsp_expand(args.body)
            end,
        },
        mapping = mapping,
        sources = {
            { name = 'nvim_lsp' },
            { name = 'nvim_lua' },
            { name = 'luasnip' },
            { name = 'spell' },
            { name = 'path' },
            { name = 'buffer' },
        },
        formatting = {
            format = function(_, vim_item)
                vim_item.kind = string.format(
                    '%s [%s]',
                    lsp.kinds[vim_item.kind],
                    vim_item.kind
                )
                return vim_item
            end,
        },
    }
end

return M
