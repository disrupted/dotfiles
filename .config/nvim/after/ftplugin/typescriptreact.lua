local opt = vim.opt
opt.formatoptions:remove 'o' -- disable comment leader when opening new line
vim.bo.shiftwidth = 2
vim.bo.tabstop = 2
vim.bo.softtabstop = 2
