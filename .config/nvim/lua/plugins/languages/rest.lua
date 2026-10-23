---@type LazeSpec
return {
    'rest-nvim/rest.nvim',
    main = 'rest-nvim',
    module = 'rest-nvim',
    cmd = 'Rest',
    keys = {
        { -- which-key group
            '<LocalLeader>r',
            nil,
            ft = 'http',
            desc = 'Request (rest.nvim)',
        },
        {
            '<LocalLeader>rr',
            '<cmd>Rest run<cr>',
            ft = 'http',
            desc = 'Run',
        },
        {
            '<LocalLeader>rl',
            '<cmd>Rest run last<cr>',
            ft = 'http',
            desc = 'Re-run last',
        },
    },
    ---@module 'rest-nvim.config'
    ---@type rest.Opts
    opts = {},
}
