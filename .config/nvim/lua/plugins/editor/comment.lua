---@type doze.Spec
return {
    src = 'https://github.com/numToStr/Comment.nvim',
    keys = {
        { 'gc', mode = { 'n', 'v' }, desc = 'Toggle linewise comment' },
        { 'gb', mode = { 'n', 'v' }, desc = 'Toggle blockwise comment' },
    },
    dependencies = { 'nvim-ts-context-commentstring' },
    config = function()
        ---@type Partial<CommentConfig>
        local opts = {
            ignore = '^$', -- ignore empty lines
            pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
        }
        require('Comment').setup(opts --[[@as CommentConfig]])
        local ft = require('Comment.ft')
        ---@diagnostic disable-next-line: inject-field
        ft.helm = { '{{/* %s */}}', '{{/* %s */}}' }
    end,
}
