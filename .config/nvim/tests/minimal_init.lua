vim.opt.runtimepath:append(vim.uv.cwd())
local plenary_path = vim.fn.stdpath 'data' .. '/lazy/plenary.nvim'
vim.opt.runtimepath:append(plenary_path)
