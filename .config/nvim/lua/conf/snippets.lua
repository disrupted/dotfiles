-----------------------------------------------------------------------------//
-- Config {{{1
-----------------------------------------------------------------------------//
local ls = require 'luasnip'
local types = require 'luasnip.util.types'

vim.cmd [[highlight LuasnipChoiceNodePassive gui=italic]]
vim.cmd [[highlight LuasnipChoiceNodeActive gui=bold]]

ls.config.set_config {
    history = true,
    ext_opts = {
        [types.choiceNode] = {
            active = {
                virt_text = { { '', 'Operator' } },
                hl_mode = 'combine',
            },
        },
        [types.insertNode] = {
            active = {
                virt_text = { { '', 'Type' } },
                hl_mode = 'combine',
            },
        },
    },
    enable_autosnippets = true,
}

-----------------------------------------------------------------------------//
-- Mappings {{{1
-----------------------------------------------------------------------------//
local map = require('utils').map
local expr = { expr = true, noremap = false, silent = false }
map(
    'i',
    '<C-e>',
    '(luasnip#choice_active() ? \'<Plug>luasnip-next-choice\' : \'<C-e>\')',
    expr
)
map(
    's',
    '<C-e>',
    '(luasnip#choice_active() ? \'<Plug>luasnip-next-choice\' : \'<C-e>\')',
    expr
)

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

-- complicated function for dynamicNode.
local function jdocsnip(args, _, old_state)
    local nodes = {
        t { '/**', ' * ' },
        i(1, 'A short Description'),
        t { '', '' },
    }

    -- These will be merged with the snippet; that way, should the snippet be updated,
    -- some user input eg. text can be referred to in the new snippet.
    local param_nodes = {}

    if old_state then
        nodes[2] = i(1, old_state.descr:get_text())
    end
    param_nodes.descr = nodes[2]

    -- At least one param.
    if string.find(args[2][1], ', ') then
        vim.list_extend(nodes, { t { ' * ', '' } })
    end

    local insert = 2
    for indx, arg in ipairs(vim.split(args[2][1], ', ', true)) do
        -- Get actual name parameter.
        arg = vim.split(arg, ' ', true)[2]
        if arg then
            local inode
            -- if there was some text in this parameter, use it as static_text for this new snippet.
            if old_state and old_state[arg] then
                inode = i(insert, old_state['arg' .. arg]:get_text())
            else
                inode = i(insert)
            end
            vim.list_extend(
                nodes,
                { t { ' * @param ' .. arg .. ' ' }, inode, t { '', '' } }
            )
            param_nodes['arg' .. arg] = inode

            insert = insert + 1
        end
    end

    if args[1][1] ~= 'void' then
        local inode
        if old_state and old_state.ret then
            inode = i(insert, old_state.ret:get_text())
        else
            inode = i(insert)
        end

        vim.list_extend(
            nodes,
            { t { ' * ', ' * @return ' }, inode, t { '', '' } }
        )
        param_nodes.ret = inode
        insert = insert + 1
    end

    if vim.tbl_count(args[3]) ~= 1 then
        local exc = string.gsub(args[3][2], ' throws ', '')
        local ins
        if old_state and old_state.ex then
            ins = i(insert, old_state.ex:get_text())
        else
            ins = i(insert)
        end
        vim.list_extend(
            nodes,
            { t { ' * ', ' * @throws ' .. exc .. ' ' }, ins, t { '', '' } }
        )
        param_nodes.ex = ins
        insert = insert + 1
    end

    vim.list_extend(nodes, { t { ' */' } })

    local snip = sn(nil, nodes)
    -- Error on attempting overwrite.
    snip.old_state = param_nodes
    return snip
end

-----------------------------------------------------------------------------//
-- Native Snippets {{{1
-----------------------------------------------------------------------------//

ls.snippets = {
    all = {
        -- trigger is fn.
        s('fn', {
            -- Simple static text.
            t '// Parameters: ',
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
        -- method
        s('def', {
            -- f(function(args)
            --     print(vim.inspect(args))
            --     return ''
            --     -- if args[2] == 'self, ' then
            --     --     return ''
            --     -- end
            --     -- if args[2] == 'cls, ' then
            --     --     return '@classmethod'
            --     -- end
            --     -- return '@staticmethod'
            -- end, 3),
            -- t '\t',
            t 'def ',
            -- Placeholder/Insert.
            i(1, 'func'),
            t '(',
            c(2, {
                t 'self, ',
                t 'cls, ',
                t '',
            }),
            -- t '(self, ',
            -- first method argument
            i(3, 'arg'),
            t ': ',
            -- argument type
            i(4, 'str'),
            t ') -> ',
            -- return type
            i(4, 'None'),
            -- Linebreak
            t { ':', '\t' },
            -- Last Placeholder, exit Point of the snippet. EVERY 'outer' SNIPPET NEEDS Placeholder 0.
            i(0, 'pass'),
        }),
        -- class
        s('class', {
            t 'class ',
            -- Placeholder/Insert.
            i(1, 'Example'),
            t { '():', '\t' },
            t 'def __init__(self, ',
            -- first field
            i(2, 'arg'),
            t ': ',
            -- argument type
            i(3, 'str'),
            -- Linebreak
            t { '):', '\t' },
            t '    self.',
            -- field name, copied from argument
            f(copy, 2),
            t ': ',
            -- field type
            f(copy, 3),
            t ' = ',
            f(copy, 2),
        }),
        -- staticmethod
        s('static', {
            t { '@staticmethod', '\t' },
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
    java = {
        -- Very long example for a java class.
        s('fn', {
            d(6, jdocsnip, { 2, 4, 5 }),
            t { '', '' },
            c(1, {
                t 'public ',
                t 'private ',
            }),
            c(2, {
                t 'void',
                t 'String',
                t 'char',
                t 'int',
                t 'double',
                t 'boolean',
                i(nil, ''),
            }),
            t ' ',
            i(3, 'myFunc'),
            t '(',
            i(4),
            t ')',
            c(5, {
                t '',
                sn(nil, {
                    t { '', ' throws ' },
                    i(1),
                }),
            }),
            t { ' {', '\t' },
            i(0),
            t { '', '}' },
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
