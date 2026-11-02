vim.keymap.set('n', '<leader>m', function()
    require('conf.marks').picker()
end, { desc = 'Marks' })
