vim.opt.formatoptions:remove 'o' -- disable comment leader when opening new line

vim.api.nvim_set_hl(0, 'LspClass', { link = '@type' }) -- e.g. `pytest.raises(ValueError)`
vim.api.nvim_set_hl(0, 'LspEnumMember', { link = '@constant' })
vim.api.nvim_set_hl(0, 'LspReadonly', { link = '@constant' }) -- e.g. `CONST="...`
vim.api.nvim_set_hl(0, 'LspDecorator', { link = '@function' }) -- e.g. `@classmethod`
-- vim.api.nvim_set_hl(0, 'LspParameter', { link = '@parameter.reference' }) -- italic
