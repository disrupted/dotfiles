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
                desc = 'Snippet: Next node',
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
                desc = 'Snippet: Prev node',
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
                desc = 'Snippet: cycle choice node',
            },
        },
        opts = function()
            local types = require 'luasnip.util.types'
            return {
                enable_autosnippets = true,
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
            }
        end,
        config = function(_, opts)
            require('luasnip').config.set_config(opts)

            vim.api.nvim_set_hl(
                0,
                'LuasnipChoiceNodePassive',
                { italic = true }
            )
            vim.api.nvim_set_hl(0, 'LuasnipChoiceNodeActive', { bold = true })

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
