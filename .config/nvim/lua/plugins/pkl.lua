---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'apple/pkl-neovim',
        ft = 'pkl',
        build = function()
            require('pkl-neovim').init()
            vim.cmd 'TSInstall pkl'
        end,
        config = function()
            -- require('luasnip.loaders.from_snipmate').lazy_load()
            vim.g.pkl_neovim = {
                start_command = { 'pkl-lsp' },
                pkl_cli_path = 'pkl',
            }
        end,
    },
}
