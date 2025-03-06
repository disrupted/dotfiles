vim.opt_local.buflisted = false
vim.opt_local.wrap = false
vim.opt_local.list = false
vim.opt_local.scrolloff = 0
vim.opt_local.winfixheight = true
vim.opt_local.signcolumn = 'auto'
vim.opt_local.statuscolumn = ''
vim.opt_local.cursorline = true
vim.opt_local.number = false
vim.opt_local.relativenumber = false
vim.opt_local.winhighlight = 'CursorLine:Visual'

vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(0, false)
end, { buffer = 0, desc = 'Close QuickFix list' })
