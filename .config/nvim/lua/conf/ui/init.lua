local M = {}

-- Methods to control the cursor
M.cursor = require('conf.ui.cursor')

vim.keymap.set('n', '<M-t>', function()
    vim.o.background = (vim.o.background == 'light') and 'dark' or 'light'
end, {
    desc = 'Toggle background between light and dark mode',
})

return M
