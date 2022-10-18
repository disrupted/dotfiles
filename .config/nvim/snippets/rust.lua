---@diagnostic disable: undefined-global

return {
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
}
