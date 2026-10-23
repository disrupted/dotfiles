---@type LazeSpec
return {
    'stevearc/quicker.nvim',
    main = 'quicker',
    module = 'quicker',
    ft = 'qf',
    init = function()
        require('which-key').add {
            {
                '<Leader>q',
                function()
                    require('quicker').toggle()
                end,
                desc = 'Toggle QuickFix list',
                icon = require('conf.icons').misc.quickfix,
            },
        }
    end,
    ---@module 'quicker'
    ---@type quicker.SetupOptions
    opts = {
        opts = { winhighlight = 'CursorLine:Visual,Delimiter:WinSeparator' },
        borders = { vert = ' ' },
        -- TODO: can we enable this with async TreeSitter
        -- highlight = {
        --     -- Load the referenced buffers to apply more accurate highlights (may be slow)
        --     load_buffers = true,
        -- },
        max_filename_width = function()
            return math.floor(math.min(95, vim.o.columns / 2))
        end,
    },
}
