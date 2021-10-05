local ls = require 'luasnip'
local types = require 'luasnip.util.types'

vim.cmd [[highlight LuasnipChoiceNodePassive gui=italic]]

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

local map = require('utils').map
map('i', '<C-e>', '<Plug>luasnip-next-choice')
map('s', '<C-e>', '<Plug>luasnip-next-choice')

vim.cmd [[autocmd User LuasnipSnippetsAdded lua print 'snippets loaded']]
vim.cmd [[packadd friendly-snippets]]
-- TODO: fix lazy_load
require('luasnip.loaders.from_vscode').load()
