---@type LazeSpec
return {
    -- move through camelCase, snake_case words better
    'chrisgrieser/nvim-spider',
    main = 'spider',
    module = 'spider',
    keys = {
        {
            'w',
            function()
                require('spider').motion('w')
            end,
            desc = 'Spider-w',
            -- NOTE: might have to use Ex commands for dot-repeat to work
            -- '<cmd>lua require(\'spider\').motion(\'w\')<CR>',
            mode = { 'n' },
        },
        {
            'w',
            function()
                ---@diagnostic disable-next-line: param-type-mismatch
                require('spider').motion('w', { skipInsignificantPunctuation = false })
            end,
            desc = 'Spider-w',
            mode = { 'o', 'x' },
        },
        {
            'e',
            function()
                require('spider').motion('e')
            end,
            desc = 'Spider-e',
            mode = { 'n', 'o', 'x' },
        },
        {
            'b',
            function()
                require('spider').motion('b')
            end,
            desc = 'Spider-b',
            mode = { 'n', 'o', 'x' },
        },
        {
            'ge',
            function()
                require('spider').motion('ge')
            end,
            desc = 'Spider-ge',
            mode = { 'n', 'o', 'x' },
        },
    },
    opts = {
        skipInsignificantPunctuation = true,
    },
}
