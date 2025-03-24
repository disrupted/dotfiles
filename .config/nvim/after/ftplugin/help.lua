vim.api.nvim_create_autocmd('BufWinEnter', {
    buffer = 0,
    command = 'wincmd L',
    desc = 'Open help in vertical split',
})
