vim.bo.buflisted = false
vim.wo.wrap = false
vim.wo.list = false
vim.wo.scrolloff = 0
vim.wo.winfixheight = true
vim.wo.signcolumn = 'auto'
vim.wo.statuscolumn = ''
vim.wo.cursorline = true
vim.wo.number = false
vim.wo.relativenumber = false
vim.wo.winhighlight = 'CursorLine:Visual'

vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(0, false)
end, { buffer = 0, desc = 'Close QuickFix list' })
