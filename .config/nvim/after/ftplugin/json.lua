vim.keymap.set('n', 'o', function()
    local line = vim.api.nvim_get_current_line()
    local should_add_comma = string.find(line, '[^,{[]$')
    if should_add_comma then
        return 'A,<CR>'
    else
        return 'o'
    end
end, {
    buffer = true,
    expr = true,
    desc = 'Open new line and insert trailing comma in previous line',
})
