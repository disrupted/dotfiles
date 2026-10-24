return {
    setup = function()
        -- test isolation: never load or write the real ShaDa (marks/history)
        vim.o.shadafile = 'NONE'
        -- tests may run where swap files cannot be created
        vim.o.swapfile = false
    end,
}
