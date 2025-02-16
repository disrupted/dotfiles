---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'L3MON4D3/LuaSnip',
        version = 'v2.*',
        lazy = true,
        build = 'make install_jsregexp',
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
            {
                '<C-e>',
                function()
                    local luasnip = require 'luasnip'
                    if luasnip.choice_active() then
                        luasnip.change_choice(1)
                    end
                end,
                mode = { 'i', 's' },
                desc = 'cycle through snippet choice node',
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
                    Snacks.notify('snippets loaded', {
                        level = vim.log.levels.DEBUG,
                        title = 'Luasnip',
                    })
                end,
            })

            require('luasnip.loaders.from_lua').lazy_load {
                paths = { './snippets' },
            }
        end,
    },
}
