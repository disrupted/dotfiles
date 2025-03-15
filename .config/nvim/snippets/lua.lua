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

local ignored_nodes = { 'string', 'comment' }

---@param node? TSNode
local function is_inside_ignored_node(node)
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    -- Use one column to the left of the cursor to avoid a "chunk" node
    -- type. Not sure what it is, but it seems to be at the end of lines in
    -- some cases.
    row, col = row - 1, col - 1
    node = node or vim.treesitter.get_node { pos = { row, col } }
    while node do
        if vim.tbl_contains(ignored_nodes, node:type()) then
            return true
        end
        node = node:parent()
    end
    return false
end

local snippets = {}
local autosnippets = {
    s(
        {
            trig = 'if',
            condition = function()
                return not is_inside_ignored_node()
            end,
        },
        fmt(
            [[
if {} then
  {}
end
  ]],
            { i(1), i(2) }
        )
    ),
}

return snippets, autosnippets
