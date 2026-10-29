---@type LazeSpec
return {
    'LiadOz/nvim-dap-repl-highlights',
    module = 'nvim-dap-repl-highlights',
    ft = 'dap-repl', -- its ftplugin injects the session's language into the REPL
    dependencies = { 'mfussenegger/nvim-dap' },
    init = function()
        -- Register the dap_repl parser for nvim-treesitter (main branch), which
        -- installs it via `ensure_installed`. Must exist before
        -- nvim-treesitter.parsers is loaded, so it can't wait for the plugin's
        -- own setup().
        vim.api.nvim_create_autocmd('User', {
            group = vim.api.nvim_create_augroup('dap_repl_parser', { clear = true }),
            pattern = 'TSUpdate',
            callback = function()
                local plugin = vim.pack.get({ 'nvim-dap-repl-highlights' })[1]
                if plugin then
                    -- inline require: the parsers table is reset on :TSUpdate
                    local parsers = require('nvim-treesitter.parsers') --[[@as table<string, table>]]
                    parsers.dap_repl = {
                        install_info = { path = plugin.path },
                    }
                end
            end,
        })
    end,
}
