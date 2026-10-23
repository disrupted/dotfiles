---@type LazeSpec
return {
    'hat0uma/csvview.nvim',
    main = 'csvview',
    module = 'csvview',
    cmd = { 'CsvViewEnable', 'CsvViewDisable', 'CsvViewToggle' },
    ft = 'csv',
    config = function()
        local csvview = require('csvview')
        csvview.setup({
            view = { header_lnum = 1 },
            parser = {
                delimiter = {
                    ft = {
                        tsv = '\t',
                    },
                    fallbacks = { ',', '\t', ';' },
                },
            },
            keymaps = {
                textobject_field_inner = { 'if', mode = { 'o', 'x' } },
                textobject_field_outer = { 'af', mode = { 'o', 'x' } },
                jump_next_field_start = { 'w', mode = { 'n', 'v' } },
                jump_prev_field_start = { 'b', mode = { 'n', 'v' } },
                jump_next_field_end = { 'e', mode = { 'n', 'v' } },
            },
        })
        vim.api.nvim_create_autocmd('FileType', {
            pattern = 'csv',
            callback = function(args)
                if not csvview.is_enabled(args.buf) then
                    csvview.enable(args.buf)
                end
            end,
        })
    end,
}
