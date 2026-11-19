---@type doze.Spec
return {
    src = 'https://github.com/NMAC427/guess-indent.nvim',
    cmd = 'GuessIndent',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {},
}
