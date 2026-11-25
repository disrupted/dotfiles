vim.keymap.set({ 'n', 'x' }, 'gc', function()
    return require('conf.comment').operator()
end, { expr = true, desc = 'Toggle comment' })
vim.keymap.set('n', 'gcc', function()
    return require('conf.comment').operator() .. '_'
end, { expr = true, desc = 'Toggle comment line' })
vim.keymap.set('n', 'gcA', function()
    require('conf.comment').append()
end, { desc = 'Add comment at end of line' })
