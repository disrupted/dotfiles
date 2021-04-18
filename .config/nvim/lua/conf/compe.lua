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

    check_back_space = function()
        local col = vim.fn.col('.') - 1
        if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
            return true
        else
            return false
        end
    end

    local opts = {silent = true, expr = true}
    vim.api.nvim_set_keymap('i', '<Tab>',
                            'pumvisible() ? "<C-n>" : v:lua.check_back_space() ? "<Tab>" : compe#complete()',
                            opts)
    vim.api.nvim_set_keymap('i', '<S-Tab>',
                            'pumvisible() ? "\\<C-p>" : "\\<S-Tab>"', opts)
    vim.api.nvim_set_keymap('i', '<C-Space>', [[compe#complete()]], opts)
    vim.api.nvim_set_keymap('i', '<C-e>', [[compe#close('<C-e>')]], opts)
    vim.api.nvim_set_keymap('i', '<CR>', [[compe#confirm('<CR>')]], opts)

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
end

return M
