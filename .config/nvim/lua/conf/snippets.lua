vim.cmd [[packadd friendly-snippets]]
local ls = require 'luasnip'
local s = ls.s
local sn = ls.sn
local t = ls.t
local i = ls.i
local f = ls.f
local c = ls.c
local d = ls.d

ls.config.set_config { history = true }

-- args is a table, where 1 is the text in Placeholder 1, 2 the text in
-- placeholder 2,...
local function copy(args)
    return args[1]
end

local function jdocsnip(args, old_state)
    local nodes = {
        t { '/**', ' * ' },
        i(1, { 'A short Description' }),
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
            vim.list_extend(nodes, {
                t { ' * @param ' .. arg .. ' ' },
                inode,
                t { '', '' },
            })
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
        vim.list_extend(nodes, {
            t { ' * ', ' * @throws ' .. exc .. ' ' },
            ins,
            t { '', '' },
        })
        param_nodes.ex = ins
        insert = insert + 1
    end

    vim.list_extend(nodes, { t { ' */' } })

    local snip = sn(nil, nodes)
    -- Error on attempting overwrite.
    snip.old_state = param_nodes
    return snip
end

ls.snippets = {
    all = {
        -- trigger is fn.
        s({ trig = 'fn' }, {
            -- Simple static text.
            t { '//Parameters: ' },
            -- function, first parameter is the function, second the Placeholders
            -- whose text it gets as input.
            f(copy, { 2 }),
            t { '', 'function ' }, -- Placeholder/Insert.
            i(1),
            t { '(' }, -- Placeholder with initial text.
            i(2, { 'int foo' }), -- Linebreak
            t { ') {', '\t' },
            -- Last Placeholder, exit Point of the snippet. EVERY 'outer' SNIPPET NEEDS Placeholder 0.
            i(0),
            t { '', '}' },
        }),
        s({ trig = 'class' }, {
            -- Choice: Switch between two different Nodes, first parameter is its position, second a list of nodes.
            c(1, { t { 'public ' }, t { 'private ' } }),
            t { 'class ' },
            i(2),
            t { ' ' },
            c(3, {
                t { '{' },
                -- sn: Nested Snippet. Instead of a trigger, it has a position, just like insert-nodes. !!! These don't expect a 0-node!!!!
                -- Inside Choices, Nodes don't need a position as the choice node is the one being jumped to.
                sn(nil, { t { 'extends ' }, i(1), t { ' {' } }),
                sn(nil, { t { 'implements ' }, i(1), t { ' {' } }),
            }),
            t { '', '\t' },
            i(0),
            t { '', '}' },
        }),
        -- Parsing snippets: First parameter: Snippet-Trigger, Second: Snippet body.
        -- Placeholders are parsed into choices with 1. the placeholder text(as a snippet) and 2. an empty string.
        -- This means they are not SELECTed like in other editors/Snippet engines.
        ls.parser.parse_snippet(
            { trig = 'lspsyn' },
            'Wow! This ${1:Stuff} really ${2:works. ${3:Well, a bit.}}'
        ),

        -- When wordTrig is set, snippets only expand as full words (lte won't expand, te will).
        ls.parser.parse_snippet(
            { trig = 'te', wordTrig = true },
            '${1:cond} ? ${2:true} : ${3:false}'
        ),

        -- When regTrig is set, trig is treated like a pattern, this snippet will expand after any number.
        ls.parser.parse_snippet(
            { trig = '%d', regTrig = true, wordTrig = true },
            'A Number!!'
        ),

        -- The last entry of args passed to the user-function is the surrounding snippet.
        s({ trig = 'a%d', regTrig = true, wordTrig = true }, {
            f(function(args)
                return { 'Triggered with ' .. args[1].trigger .. '.' }
            end, {}),
            i(0),
        }), -- It's possible to use capture-groups inside regex-triggers.
        s({ trig = 'b(%d)', regTrig = true, wordTrig = true }, {
            f(function(args)
                return { 'Captured Text: ' .. args[1].captures[1] .. '.' }
            end, {}),
            i(0),
        }),
    },
    java = {
        -- Very long example for a java class.
        s({ trig = 'fn' }, {
            d(6, jdocsnip, { 2, 4, 5 }),
            t { '', '' },
            c(1, { t { 'public ' }, t { 'private ' } }),
            c(2, {
                t { 'void' },
                t { 'String' },
                t { 'char' },
                t { 'int' },
                t { 'double' },
                t { 'boolean' },
                i(nil, { '' }),
            }),
            t { ' ' },
            i(3, { 'myFunc' }),
            t { '(' },
            i(4),
            t { ')' },
            c(5, { t { '' }, sn(nil, { t { '', ' throws ' }, i(1) }) }),
            t { ' {', '\t' },
            i(0),
            t { '', '}' },
        }),
    },
    -- python = {
    --     s({trig = "def"}, {
    --         -- Simple static text.
    --         t({"# Parameters: "}),
    --         -- function, first parameter is the function, second the Placeholders
    --         -- whose text it gets as input.
    --         f(copy, {2}), t({"", "def "}), -- Placeholder/Insert.
    --         i(1), t({"("}), -- Placeholder with initial text.
    --         i(2, {"foo"}), -- Linebreak
    --         t({"):", "\t"}),
    --         -- Last Placeholder, exit Point of the snippet. EVERY 'outer' SNIPPET NEEDS Placeholder 0.
    --         i(0), t({"", ""})
    --     })
    -- }
}

--[[
-- Beside defining your own snippets you can also load snippets from "vscode-like" packages defining
-- that expose snippets in json files, for example <https://github.com/rafamadriz/friendly-snippets>.
-- Mind that this will extend  `ls.snippets` so you need to do it after your own snippets or you
-- will need to extend the table yourself instead of setting a new one.
]]

require('luasnip.loaders.from_vscode').load()
