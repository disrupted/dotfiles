vim.keymap.set('n', '<Leader>gP', function()
    vim.async.run(require('conf.forge').create_or_open_current):raise_on_error()
end, { desc = 'View or create PR' })
