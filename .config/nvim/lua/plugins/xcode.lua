---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'wojciech-kulik/xcodebuild.nvim',
        ft = 'swift',
        dependencies = { 'MunifTanjim/nui.nvim' },
        -- opts = {},
        config = function()
            require('xcodebuild').setup {
                -- put some options here or leave it empty to use default settings
            }
        end,
    },
}
