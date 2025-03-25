---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'hat0uma/csvview.nvim',
        cmd = { 'CsvViewEnable', 'CsvViewDisable', 'CsvViewToggle' },
        ft = 'csv',
        ---@module 'csvview'
        ---@type CsvView.Options
        opts = { view = { header_lnum = 1 } },
        config = function(_, opts)
            local csvview = require 'csvview'
            csvview.setup(opts)
            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'csv',
                callback = function(args)
                    if not csvview.is_enabled(args.buf) then
                        csvview.enable(args.buf)
                    end
                end,
            })
        end,
    },
}
