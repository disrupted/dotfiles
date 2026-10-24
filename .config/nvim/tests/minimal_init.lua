vim.opt.runtimepath:append(vim.uv.cwd())
-- test isolation: never load or write the real ShaDa (marks/history)
vim.o.shadafile = 'NONE'
-- tests may run where swap files cannot be created
vim.o.swapfile = false
local plenary_path = vim.fn.stdpath('data') .. '/lazy/plenary.nvim'
vim.opt.runtimepath:append(plenary_path)
