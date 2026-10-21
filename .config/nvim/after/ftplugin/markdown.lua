-- remove conflicting keymaps
vim.keymap.del('n', '[[', { buffer = true })
vim.keymap.del('n', ']]', { buffer = true })

if
    (vim.bo.readonly or vim.bo.buftype == 'nofile')
    and vim.wo[0][0].conceallevel == 0
then
    vim.wo[0][0].conceallevel = 2
    vim.wo[0][0].concealcursor = 'n'
end
