---@type LazeSpec
return {
    -- 'folke/which-key.nvim',
    'disrupted/which-key.nvim',
    main = 'which-key',
    module = 'which-key',
    lazy = false,
    priority = 999,
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 500
    end,
    config = function()
        ---@module 'which-key.config'
        ---@type wk.Opts
        local opts = {
            preset = 'helix',
            ---@param mapping wk.Mapping
            filter = function(mapping)
                -- exclude mappings without a description
                return mapping.desc and mapping.desc ~= ''
            end,
            spec = {
                { '<Leader>?', hidden = true },
                -- override motions preset
                { ',', desc = '' },
                { ';', desc = '' },
            },
            icons = {
                rules = {
                    {
                        plugin = 'opencode.nvim',
                        icon = ' ',
                        color = 'yellow',
                    },
                    {
                        plugin = 'opencode.nvim',
                        pattern = 'reasoning',
                        icon = '󱍎 ',
                    },
                    {
                        plugin = 'opencode.nvim',
                        pattern = 'tool',
                        icon = ' ',
                    },
                },
            },
        }
        local wk = require('which-key')
        ---@diagnostic disable-next-line: param-type-mismatch
        wk.setup(opts)

        wk.add({
            {
                '<Leader>?',
                function()
                    wk.show({ global = false })
                end,
                desc = 'Buffer keymaps',
                icon = '󰘳',
            },
        })
    end,
}
