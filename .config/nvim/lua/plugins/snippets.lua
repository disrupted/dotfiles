return {
    {
        'L3MON4D3/LuaSnip',
        lazy = true,
        keys = {
            {
                '<C-j>',
                function()
                    local luasnip = require 'luasnip'
                    if luasnip.jumpable(1) then
                        luasnip.jump(1)
                    end
                end,
                mode = { 'i', 's' },
                desc = 'jump to next snippet',
            },
            {
                '<C-k>',
                function()
                    local luasnip = require 'luasnip'
                    if luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    end
                end,
                mode = { 'i', 's' },
                desc = 'jump to previous snippet',
            },
        },
        opts = {},
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

            vim.api.nvim_create_autocmd('User', {
                pattern = 'LuasnipSnippetsAdded',
                callback = function()
                    print 'snippets loaded'
                end,
            })

            require('luasnip.loaders.from_lua').lazy_load {
                paths = { './snippets' },
            }
        end,
        dependencies = {
            'rafamadriz/friendly-snippets',
            config = function()
                require('luasnip.loaders.from_vscode').lazy_load()
            end,
            enabled = false,
        },
    },
}
