---@type LazeSpec
return {
    -- TODO: switch back to folke/todo-comments.nvim once
    -- https://github.com/folke/todo-comments.nvim/pull/395 merges.
    'dtor/todo-comments.nvim',
    branch = 'remove-plenary',
    main = 'todo-comments',
    module = 'todo-comments',
    cmd = { 'TodoQuickFix', 'TodoTrouble' },
    keys = {
        {
            '[c',
            function()
                require('todo-comments').jump_prev()
            end,
            desc = 'Prev todo comment',
        },
        {
            ']c',
            function()
                require('todo-comments').jump_next()
            end,
            desc = 'Next todo comment',
        },
    },
    init = function()
        vim.api.nvim_create_user_command('Todo', 'TodoTrouble', {})
        vim.api.nvim_create_user_command('TodoBuffer', 'TodoTrouble filter.buf=0', {})
    end,
    config = function()
        local opts = {
            search = { pattern = [[\b(KEYWORDS)(\([^\)]*\))?:]] },
            highlight = { pattern = [[.*<((KEYWORDS)%(\(.{-1,}\))?):]] },
        }
        -- HACK: no option to disable highlighting globally
        ---@diagnostic disable-next-line: duplicate-set-field
        require('todo-comments.highlight').start = function() end
        require('todo-comments').setup(opts)
    end,
}
