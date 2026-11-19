---@type doze.Spec
return {
    src = 'https://github.com/wojciech-kulik/xcodebuild.nvim',
    ft = 'swift',
    dependencies = { 'nui.nvim' },
    config = function()
        require('xcodebuild').setup({})
    end,
}
