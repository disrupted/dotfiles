---@type doze.Spec
return {
    src = 'https://github.com/tar80/matchwith.nvim',
    enabled = false, -- FIXME: plugin bugs cause some errors
    event = { 'BufWinEnter', 'BufNewFile' },
    ---@module 'matchwith.config'
    ---@type Options
    opts = {
        jump_key = '%',
        ignore_filetypes = {},
    },
}
