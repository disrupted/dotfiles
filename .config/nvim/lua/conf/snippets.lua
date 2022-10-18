-----------------------------------------------------------------------------//
-- Config {{{1
-----------------------------------------------------------------------------//
local ls = require 'luasnip'
local types = require 'luasnip.util.types'

vim.api.nvim_set_hl(0, 'LuasnipChoiceNodePassive', { italic = true })
vim.api.nvim_set_hl(0, 'LuasnipChoiceNodeActive', { bold = true })

ls.config.set_config {
    history = true,
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

-----------------------------------------------------------------------------//
-- Mappings {{{1
-----------------------------------------------------------------------------//
local expr = { expr = true, remap = true, silent = false }
vim.keymap.set(
    'i',
    '<C-e>',
    '(luasnip#choice_active() ? \'<Plug>luasnip-next-choice\' : \'<C-e>\')',
    expr
)
vim.keymap.set(
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
-- local l = require('luasnip.extras').lambda
-- local r = require('luasnip.extras').rep
-- local p = require('luasnip.extras').partial
-- local m = require('luasnip.extras').match
-- local n = require('luasnip.extras').nonempty
-- local dl = require('luasnip.extras').dynamic_lambda
-- local fmt = require('luasnip.extras.fmt').fmt
-- local fmta = require('luasnip.extras.fmt').fmta
-- local conds = require 'luasnip.extras.conditions'

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
    for _, arg in ipairs(vim.split(args[2][1], ', ', true)) do
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

ls.add_snippets('all', {
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
        -- Last Placeholder, exit Point of the snippet.
        i(0),
        t { '', '}' },
    }),
})

ls.add_snippets('python', {
    -- method
    s({
        trig = 'def',
        name = 'def method',
        dscr = {
            'def func(arg: str) -> None:',
        },
    }, {
        -- decorator
        f(function(args)
            if args[1][1] == 'cls, ' then
                return { '@classmethod', '' }
            end
            if args[1][1] == '' then
                return { '@staticmethod', '' }
            end
            return ''
        end, 2),
        t 'def ',
        -- method name
        i(1, 'func'),
        t '(',
        c(2, {
            t 'self, ',
            t 'cls, ',
            t '',
        }),
        -- first method argument
        i(3, 'arg'),
        t ': ',
        -- argument type
        i(4, 'str'),
        t ') -> ',
        -- return type
        i(5, 'None'),
        -- linebreak
        t { ':', '\t' },
        i(0, 'pass'),
    }),
    -- property
    s({
        trig = '@property',
        name = 'property',
        dscr = {
            'New property: get and set via decorator',
        },
    }, {
        -- decorator
        t { '@property', '' },
        t 'def ',
        -- method name
        i(1, 'foo'),
        t '(self) -> ',
        -- return type
        i(2, 'str'),
        -- linebreak
        t { ':', '\t' },
        t 'return self._',
        -- field name, copied from argument
        f(copy, 1),
        -- empty lines
        t { '', '', '' },
        -- setter
        t { '@' },
        f(copy, 1),
        t { '.setter', '' },
        t 'def ',
        f(copy, 1),
        t '(self, ',
        f(copy, 1),
        t ': ',
        f(copy, 2),
        t { ') -> None:', '\t' },
        t 'self._',
        f(copy, 1),
        t ' = ',
        f(copy, 1),
    }),
    -- class
    s('class', {
        t 'class ',
        -- placeholder/insert.
        i(1, 'Example'),
        c(2, {
            t '',
            -- base class
            sn(nil, {
                t '(',
                i(1),
                t ')',
            }),
        }),
        t { ':', '\t' },
        t 'def __init__(self, ',
        -- first field
        i(3, 'arg'),
        t ': ',
        -- argument type
        i(4, 'str'),
        -- linebreak
        t { ') -> None:', '\t\t' },
        t 'self.',
        -- field name, copied from argument
        f(copy, 3),
        t ': ',
        -- field type
        f(copy, 4),
        t ' = ',
        f(copy, 3),
        t { '', '\t\t' },
        i(0),
    }),
    s('main', {
        t { 'if __name__ == "__main__":', '\t' },
        i(0, 'main()'),
    }),
    s({
        trig = 'env',
        name = 'shebang',
        dscr = {
            'python shebang',
        },
    }, {
        t { '#!/usr/bin/env python3' },
    }),
    s({
        trig = 'from',
        name = 'from … import …',
        dscr = {
            'import from module',
        },
    }, {
        t { 'from ' },
        i(1, ''),
        t { ' import ' },
        i(0, ''),
    }),
    s({
        trig = 'if',
        name = 'if …:',
        dscr = {
            'if condition',
        },
    }, {
        t { 'if ' },
        i(1, ''),
        t { ':', '\t' },
        i(0, 'pass'),
    }),
    s({
        trig = 'for',
        name = 'for …:',
        dscr = {
            'for loop',
        },
    }, {
        t { 'for ' },
        i(1, 'i'),
        t { ' in ' },
        c(2, {
            i(nil, 'iterable'),
            sn(nil, {
                t 'range(',
                i(1, '10'),
                t ')',
            }),
        }),
        t { ':', '\t' },
        i(0, 'pass'),
    }),
    s({
        trig = 'try',
        name = 'try … except',
        dscr = {
            'try-except-block',
        },
    }, {
        t { 'try:', '\t' },
        i(1, 'pass'),
        t { '', 'except ' },
        i(2, 'exception'),
        t { ' as ' },
        i(3, 'e'),
        t { ':', '\t' },
        c(4, {
            sn(nil, {
                t 'raise ',
                i(1, 'e'),
            }),
            i(nil, 'pass'),
        }),
        i(0),
    }),
})

ls.add_snippets('rust', {
    s({
        trig = 'fn',
        name = 'function',
        dscr = {
            'fn …(…) { … }',
        },
    }, {
        t 'fn ',
        -- function name
        i(1, 'func'),
        t '(',
        -- first method argument
        i(2, 'arg'),
        t ': ',
        -- argument type
        i(3, '&str'),
        t ') -> ',
        -- return type
        i(4, '&str'),
        -- Linebreak
        t { ' {', '\t' },
        i(0, ''),
        t { '', '}' },
    }),
})

ls.add_snippets('lua', {
    s({ -- from akinsho
        trig = 'use',
        name = 'packer use',
        dscr = {
            'packer use plugin block',
            'e.g.',
            'use {\'author/plugin\'}',
        },
    }, {
        t 'use { \'',
        -- Get the author and URL in the clipboard and auto populate the author and project
        f(function(_)
            local default = 'author/plugin'
            local clip = vim.fn.getreg '*'
            if not vim.startswith(clip, 'https://github.com/') then
                return default
            end
            local parts = vim.split(clip, '/')
            if #parts < 2 then
                return default
            end
            local author, project = parts[#parts - 1], parts[#parts]
            return author .. '/' .. project
        end, {}),
        t '\' ',
        i(2, { ', config = function()', '', 'end' }),
        t '}',
    }),
})

ls.add_snippets('java', {
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
})
-----------------------------------------------------------------------------//
-- External Snippets {{{1
-----------------------------------------------------------------------------//
vim.api.nvim_create_autocmd('User', {
    pattern = 'LuasnipSnippetsAdded',
    callback = function()
        print 'snippets loaded'
    end,
})
require('luasnip.loaders.from_vscode').lazy_load { paths = './snippets' }

-----------------------------------------------------------------------------//
-- }}}1
-----------------------------------------------------------------------------//
