local M = {}

function M.config()
    vim.lsp.protocol.CompletionItemKind =
        {
            "ﮜ [text]", " [method]", " [function]", " [constructor]",
            "ﰠ [field]", " [variable]", " [class]", " [interface]",
            " [module]", " [property]", " [unit]", " [value]",
            " [enum]", " [key]", " [snippet]", " [color]",
            " [file]", " [reference]", " [folder]",
            " [enum member]", " [constant]", " [struct]",
            "⌘ [event]", " [operator]", "⌂ [type]"
        }

    -- vim.cmd [[packadd LuaSnip]]
    local compe = require 'compe'
    compe.setup {
        enabled = true,
        debug = false,
        min_length = 2,
        preselect = 'disable',
        source_timeout = 200,
        incomplete_delay = 400,
        allow_prefix_unmatch = false,
        source = {
            path = {menu = '[PATH]', priority = 9},
            -- treesitter = {menu = '[TS]', priority = 9},
            buffer = {menu = '[BUF]', priority = 8},
            nvim_lsp = {menu = '[LSP]', priority = 10, sort = false},
            nvim_lua = {menu = '[LUA]', priority = 6},
            luasnip = {menu = '[SNP]', priority = 10},
            spell = true
        }
    }

    local t = function(str)
        return vim.api.nvim_replace_termcodes(str, true, true, true)
    end

    local check_back_space = function()
        local col = vim.fn.col('.') - 1
        if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
            return true
        else
            return false
        end
    end

    -- Use Tab / S-Tab to:
    -- move to prev/next item in completion menuone
    -- jump to prev/next snippet's placeholder
    _G.tab_complete = function()
        if vim.fn.pumvisible() == 1 then
            return t "<C-n>"
        elseif require'luasnip'.expand_or_jumpable() then
            return t "<Plug>luasnip-expand-or-jump"
        elseif check_back_space() then
            return t "<Tab>"
        else
            return vim.fn['compe#complete']()
        end
    end
    _G.s_tab_complete = function()
        if vim.fn.pumvisible() == 1 then
            return t "<C-p>"
        elseif require'luasnip'.jumpable(-1) then
            return t "<Plug>luasnip-jump-prev"
        else
            return t "<S-Tab>"
        end
    end

    local opts = {silent = true, expr = true}
    vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", opts)
    vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", opts)
    vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", opts)
    vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", opts)
    vim.api.nvim_set_keymap('i', '<C-e>', [[compe#close('<C-e>')]], opts)
    vim.api.nvim_set_keymap('i', '<CR>', [[compe#confirm('<CR>')]], opts)
    vim.api.nvim_set_keymap('i', '<C-Space>', [[compe#complete()]], opts)

    -- From https://github.com/hydeik/dotfiles/blob/47d80c4d37a6bda7db236d61deefdd989dcd0f3b/editors/nvim/lua/plugins/completion.lua
    -- We have to register sources manually, because packadd doesn't source
    -- files from `after` directory inside `opt` directory.
    -- See https://github.com/vim/vim/issues/1994
    -- for _, src in ipairs {
    --     "path", "buffer", "nvim_lua", "nvim_lsp", "snippets_nvim", "spell",
    --     "treesitter"
    -- } do
    --     vim.g["loaded_compe_" .. src] = true
    --     compe.register_source(src, require("compe_" .. src))
    -- end
    -- vim.g.loaded_compe_nvim_lsp = true
    -- require("compe_nvim_lsp").attach()
    --
    -- vim.g.loaded_compe_luasnip = true
    -- compe.register_source("luasnip", require 'compe_luasnip')
    -- vim.g.loaded_compe_nvim_lsp = true
    -- require'compe_nvim_lsp'.attach()
end

return M
