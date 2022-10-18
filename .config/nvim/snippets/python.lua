---@diagnostic disable: undefined-global

local function copy(args)
    return args[1]
end

return {
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
}
