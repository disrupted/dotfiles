---@type doze.Spec
return {
    -- 'folke/which-key.nvim',
    src = 'https://github.com/disrupted/which-key.nvim',
    lazy = false,
    priority = 999,
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 500
    end,
    config = function()
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
        }
        local wk = require('which-key')
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
