-----------------------------------------------------------------------------//
-- Config {{{1
-----------------------------------------------------------------------------//
local ls = require 'luasnip'
local types = require 'luasnip.util.types'

ls.config.set_config {
    history = true,
    ext_opts = {
        [types.choiceNode] = {
            active = {
                virt_text = { { '●', 'Operator' } },
            },
        },
        [types.insertNode] = {
            active = {
                virt_text = { { '●', 'Type' } },
            },
        },
    },
    enable_autosnippets = true,
}

vim.cmd [[highlight LuasnipChoiceNodePassive gui=italic]]

-----------------------------------------------------------------------------//
-- Mappings {{{1
-----------------------------------------------------------------------------//
local map = require('utils').map
map('i', '<C-e>', '<Plug>luasnip-next-choice')
map('s', '<C-e>', '<Plug>luasnip-next-choice')

-----------------------------------------------------------------------------//
-- Helpers {{{1
-----------------------------------------------------------------------------//
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local l = require('luasnip.extras').lambda
local r = require('luasnip.extras').rep
local p = require('luasnip.extras').partial
local m = require('luasnip.extras').match
local n = require('luasnip.extras').nonempty
local dl = require('luasnip.extras').dynamic_lambda
local fmt = require('luasnip.extras.fmt').fmt
local fmta = require('luasnip.extras.fmt').fmta
local conds = require 'luasnip.extras.conditions'

local function copy(args)
    return args[1]
end

-----------------------------------------------------------------------------//
-- Native Snippets {{{1
-----------------------------------------------------------------------------//

ls.snippets = {
    all = {
        -- trigger is fn.
        s('fn', {
            -- Simple static text.
            t '//Parameters: ',
            -- function, first parameter is the function, second the Placeholders
            -- whose text it gets as input.
            f(copy, 2),
            t { '', 'function ' },
            -- Placeholder/Insert.
            i(1),
            t '(',
            -- Placeholder with initial text.
            i(2, 'int foo'),
            -- Linebreak
            t { ') {', '\t' },
            -- Last Placeholder, exit Point of the snippet. EVERY 'outer' SNIPPET NEEDS Placeholder 0.
            i(0),
            t { '', '}' },
        }),
        s('class', {
            -- Choice: Switch between two different Nodes, first parameter is its position, second a list of nodes.
            c(1, {
                t 'public ',
                t 'private ',
            }),
            t 'class ',
            i(2),
            t ' ',
            c(3, {
                t '{',
                -- sn: Nested Snippet. Instead of a trigger, it has a position, just like insert-nodes. !!! These don't expect a 0-node!!!!
                -- Inside Choices, Nodes don't need a position as the choice node is the one being jumped to.
                sn(nil, {
                    t 'extends ',
                    i(1),
                    t ' {',
                }),
                sn(nil, {
                    t 'implements ',
                    i(1),
                    t ' {',
                }),
            }),
            t { '', '\t' },
            i(0),
            t { '', '}' },
        }),
    },
    python = {
        s('def', {
            t 'def ',
            -- Placeholder/Insert.
            i(1, 'func'),
            t '(',
            -- first method argument
            i(2, 'arg'),
            t ': ',
            -- argument type
            i(3, 'str'),
            t ') -> ',
            -- return type
            i(4, 'None'),
            -- Linebreak
            t { ':', '\t' },
            -- Last Placeholder, exit Point of the snippet. EVERY 'outer' SNIPPET NEEDS Placeholder 0.
            i(0, 'pass'),
        }),
    },
}

-----------------------------------------------------------------------------//
-- External Snippets {{{1
-----------------------------------------------------------------------------//
vim.cmd [[autocmd User LuasnipSnippetsAdded lua print 'snippets loaded']]
-- vim.cmd [[packadd friendly-snippets]]
-- TODO: fix lazy_load
-- require('luasnip.loaders.from_vscode').load()

-----------------------------------------------------------------------------//
-- }}}1
-----------------------------------------------------------------------------//
