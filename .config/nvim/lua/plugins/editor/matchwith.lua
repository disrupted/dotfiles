---@type LazeSpec
return {
    'tar80/matchwith.nvim',
    enabled = false, -- FIXME: plugin bugs cause some errors
    main = 'matchwith',
    module = 'matchwith',
    event = { 'BufWinEnter', 'BufNewFile' },
    ---@module 'matchwith.config'
    ---@type Options
    opts = {
        jump_key = '%',
        ignore_filetypes = {},
    },
}
