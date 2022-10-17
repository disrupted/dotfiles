local M = {}

function M.setup()
    local opts = { noremap = true, silent = true, expr = true }
    vim.keymap.set('n', '<leader>j', function()
        return require('dial.map').inc_normal()
    end, opts)
    vim.keymap.set('n', '<leader>k', function()
        return require('dial.map').dec_normal()
    end, opts)
    vim.keymap.set('v', '<leader>j', function()
        return require('dial.map').inc_visual()
    end, opts)
    vim.keymap.set('v', '<leader>k', function()
        return require('dial.map').dec_visual()
    end, opts)
end

function M.config()
    local augend = require 'dial.augend'
    require('dial.config').augends:register_group {
        default = {
            augend.integer.alias.decimal,
            augend.constant.alias.bool,
            augend.semver.alias.semver,
            augend.date.alias['%Y/%m/%d'], -- date (2022/02/20, etc.)
            augend.constant.new {
                elements = { 'and', 'or' },
                word = true,
                cyclic = true,
            },
            augend.constant.new {
                elements = { '&&', '||' },
                word = false,
                cyclic = true,
            },
        },
    }
end

return M
