---@type doze.Spec
return {
    src = 'https://github.com/tar80/matchwith.nvim',
    enabled = false, -- FIXME: plugin bugs cause some errors
    event = { 'BufWinEnter', 'BufNewFile' },
    config = function()
        ---@type Options
        local opts = {
            jump_key = '%',
            ignore_filetypes = {},
        }
        require('matchwith').setup(opts)
    end,
}
