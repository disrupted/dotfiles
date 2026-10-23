---@type LazeSpec
return {
    'NicholasZolton/neojj',
    main = 'neojj',
    module = 'neojj',
    keys = {
        {
            '<Leader>gj',
            function()
                require('neojj').open { kind = 'tab' }
                vim.cmd.tabmove()
            end,
            desc = 'Neojj',
        },
    },
    ---@module 'neojj.config'
    ---@type NeojjConfig
    opts = {
        disable_hint = true,
        disable_signs = true,
        integrations = {
            codediff = true,
            snacks = true,
        },
        diff_viewer = 'codediff',
        graph_style = 'kitty',
        status = {
            recent_commit_count = 50,
        },
        process_spinner = true,
    },
}
