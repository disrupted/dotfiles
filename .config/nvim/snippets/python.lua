local ls = require 'luasnip'
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local l = require('luasnip.extras').lambda
local rep = require('luasnip.extras').rep
local p = require('luasnip.extras').partial
local m = require('luasnip.extras').match
local n = require('luasnip.extras').nonempty
local dl = require('luasnip.extras').dynamic_lambda
local fmt = require('luasnip.extras.fmt').fmt
local fmta = require('luasnip.extras.fmt').fmta
local types = require 'luasnip.util.types'
local conds = require 'luasnip.extras.conditions'
local conds_expand = require 'luasnip.extras.conditions.expand'

local function copy(args)
    return args[1]
end

local ignored_nodes = { 'string', 'comment' }

---@param node? TSNode
local function is_inside_ignored_node(node)
    node = node or vim.treesitter.get_node()
    while node do
        if vim.tbl_contains(ignored_nodes, node:type()) then
            return true
        end
        node = node:parent()
    end
    return false
end

---@param node? TSNode
local function is_inside_class(node)
    node = node or vim.treesitter.get_node()
    while node do
        if node:type() == 'function_definition' then
            return false
        end
        if node:type() == 'class_definition' then
            return true
        end
        node = node:parent()
    end
    return false
end

local snippets = {
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
    }, {
        show_condition = function(line_to_cursor)
            return #vim.trim(line_to_cursor) == 0
        end,
    }),
    s({
        trig = 'property', -- FIXME: blink.cmp doesn't match @property
        name = 'property',
        dscr = { 'New property: get and set via decorator' },
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
    }, {
        show_condition = function(line_to_cursor)
            return #vim.trim(line_to_cursor) == 0 and is_inside_class()
        end,
    }),
    s('main', {
        t { 'if __name__ == "__main__":', '\t' },
        i(0, 'main()'),
    }, {
        show_condition = function(line_to_cursor)
            local bufname = vim.api.nvim_buf_get_name(0)
            return bufname:match 'main%.py' and line_to_cursor == ''
        end,
    }),
    s({
        trig = 'env',
        name = 'shebang',
        dscr = { 'Python shebang' },
    }, {
        t { '#!/usr/bin/env python3' },
    }, {
        show_condition = function(line_to_cursor)
            return line_to_cursor == ''
        end,
    }),
}

local autosnippets = {
    -- function
    s({
        trig = 'def',
        name = 'def function',
        dscr = { 'def func(arg: str) -> None:' },
        condition = function(line_to_cursor)
            return vim.trim(line_to_cursor) == 'def' -- beginning of the line
                and not is_inside_ignored_node()
                and not is_inside_class()
        end,
    }, {
        t 'def ',
        -- function name
        i(1, 'func'),
        t '(',
        -- first function argument
        i(2, 'arg'),
        t ': ',
        -- argument type
        i(3, 'str'),
        t ') -> ',
        -- return type
        i(4, 'None'),
        -- linebreak
        t { ':', '\t' },
        i(0, 'pass'),
    }),
    -- method
    s({
        trig = 'def',
        name = 'def method',
        dscr = { 'def method(self, arg: str) -> None:' },
        condition = function(line_to_cursor)
            return vim.trim(line_to_cursor) == 'def' -- beginning of the line
                and not is_inside_ignored_node()
                and is_inside_class()
        end,
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
        i(1, 'method'),
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
    s({
        trig = 'from',
        name = 'from … import …',
        dscr = { 'import from module' },
        condition = function(line_to_cursor)
            return vim.trim(line_to_cursor) == 'from' -- beginning of the line
                and not is_inside_ignored_node()
        end,
    }, {
        t { 'from ' },
        i(1, ''),
        t { ' import ' },
        i(0, ''),
    }),
    s({
        trig = 'if',
        name = 'if …:',
        dscr = { 'if condition' },
        condition = function(line_to_cursor)
            return vim.trim(line_to_cursor) == 'if' -- beginning of the line
                and not is_inside_ignored_node()
        end,
    }, {
        t { 'if ' },
        i(1, ''),
        t { ':', '\t' },
        i(0, 'pass'),
    }),
    s({
        trig = 'for',
        name = 'for …:',
        dscr = { 'for loop' },
        condition = function(line_to_cursor)
            return vim.trim(line_to_cursor) == 'for' -- beginning of the line
                and not is_inside_ignored_node()
        end,
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
        dscr = { 'try-except-block' },
        condition = function(line_to_cursor)
            return vim.trim(line_to_cursor) == 'try' -- beginning of the line
                and not is_inside_ignored_node()
        end,
    }, {
        t { 'try:', '\t' },
        i(1, 'pass'),
        t { '', 'except ' },
        i(2, 'Exception'),
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
}

return snippets, autosnippets
