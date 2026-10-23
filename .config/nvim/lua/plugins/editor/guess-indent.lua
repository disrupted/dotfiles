---@type LazeSpec
return {
    'NMAC427/guess-indent.nvim',
    main = 'guess-indent',
    module = 'guess-indent',
    cmd = 'GuessIndent',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {},
}
