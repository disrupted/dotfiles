---@type LazeSpec
return {
    'LiadOz/nvim-dap-repl-highlights',
    module = 'nvim-dap-repl-highlights',
    ft = 'dap-repl', -- its ftplugin injects the session's language into the REPL
    dependencies = { 'mfussenegger/nvim-dap' },
    init = function()
        -- Register the dap_repl parser with nvim-treesitter. This must happen
        -- before nvim-treesitter.parsers loads, so it can't wait for setup().
        -- TSUpdate fires on every parsers reload, so keep the callback cheap
        -- (vim.pack.get() takes ~135ms).
        local path = vim.fs.joinpath(
            vim.fn.stdpath('data') --[[@as string]],
            'site/pack/core/opt/nvim-dap-repl-highlights'
        )
        vim.api.nvim_create_autocmd('User', {
            group = vim.api.nvim_create_augroup('dap_repl_parser', { clear = true }),
            pattern = 'TSUpdate',
            callback = function()
                if vim.uv.fs_stat(path) then
                    -- the parsers table is reset on :TSUpdate, so require it here
                    local parsers = require('nvim-treesitter.parsers') --[[@as table<string, table>]]
                    parsers.dap_repl = {
                        install_info = { path = path },
                    }
                end
            end,
        })
    end,
}
