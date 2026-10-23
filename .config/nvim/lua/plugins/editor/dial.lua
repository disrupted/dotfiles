---@type LazeSpec
return {
    'monaqa/dial.nvim',
    main = 'dial',
    init = function()
        require('which-key').add({
            mode = { 'n', 'v' },
            { '<Leader>j', desc = 'Increment value', icon = '' },
            { '<Leader>k', desc = 'Decrement value', icon = '' },
        })
    end,
    keys = {
        { '<Leader>j', mode = { 'n', 'v' } },
        { '<Leader>k', mode = { 'n', 'v' } },
    },
    config = function()
        local augend = require('dial.augend')
        require('dial.config').augends:register_group({
            default = {
                augend.integer.alias.decimal,
                augend.constant.alias.bool,
                augend.constant.new({
                    elements = { 'True', 'False' },
                    word = true,
                    cyclic = true,
                }),
                augend.semver.alias.semver,
                augend.date.alias['%Y/%m/%d'], -- date (2022/02/20, etc.)
                augend.constant.new({
                    elements = { 'and', 'or' },
                    word = true,
                    cyclic = true,
                }),
                augend.constant.new({
                    elements = { '&&', '||' },
                    word = false,
                    cyclic = true,
                }),
            },
        })

        local map = require('dial.map')
        vim.keymap.set('n', '<Leader>j', map.inc_normal, { expr = true })
        vim.keymap.set('n', '<Leader>k', map.dec_normal, { expr = true })
        vim.keymap.set('v', '<Leader>j', map.inc_visual, { expr = true })
        vim.keymap.set('v', '<Leader>k', map.dec_visual, { expr = true })
    end,
}
