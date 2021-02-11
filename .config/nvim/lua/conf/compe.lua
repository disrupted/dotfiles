local M = {}

function M.setup()
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

    require'compe'.setup {
        enabled = true,
        debug = false,
        min_length = 2,
        preselect = 'disable',
        source_timeout = 200,
        incomplete_delay = 400,
        allow_prefix_unmatch = false,
        source = {
            path = {menu = '[PATH]', priority = 9},
            treesitter = {menu = '[TS]', priority = 9},
            buffer = {menu = '[BUF]', priority = 8},
            nvim_lsp = {menu = '[LSP]', priority = 10, sort = false},
            nvim_lua = {menu = '[LUA]', priority = 8},
            snippets_nvim = {menu = '[SNP]', priority = 10},
            spell = true
        }
    }

    vim.api.nvim_set_keymap('i', '<Tab>',
                            'pumvisible() ? "\\<C-n>" : "\\<Tab>"',
                            {expr = true})
    vim.api.nvim_set_keymap('i', '<S-Tab>',
                            'pumvisible() ? "\\<C-p>" : "\\<Tab>"',
                            {expr = true})
end

return M
