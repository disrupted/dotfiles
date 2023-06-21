return {
    {
        'numToStr/Navigator.nvim',
        cond = os.getenv 'TMUX' ~= vim.NIL,
        keys = {
            {
                '<C-w>j',
                function()
                    require('Navigator').down()
                end,
            },
            {
                '<C-w>k',
                function()
                    require('Navigator').up()
                end,
            },
            {
                '<C-w>h',
                function()
                    require('Navigator').left()
                end,
            },
            {
                '<C-w>l',
                function()
                    require('Navigator').right()
                end,
            },
        },
        opts = { auto_save = 'all', disable_on_zoom = false },
    },
    {
        'ggandor/lightspeed.nvim',
        lazy = true,
        keys = {
            -- { 's', mode = { 'n', 'x' } },
            -- { 'S', mode = { 'n', 'x' } },
            { 's', mode = 'n' },
            { 'S', mode = 'n' },
            { 'z', mode = 'o' },
            { 'Z', mode = 'o' },
            { 'x', mode = 'o' },
            { 'X', mode = 'o' },
            { 'f', mode = { 'n', 'x', 'o' } },
            { 'F', mode = { 'n', 'x', 'o' } },
        },
        opts = {
            ignore_case = true,
            exit_after_idle_msecs = { labeled = 4000, unlabeled = 3000 },
        },
    },
    {
        'ggandor/leap.nvim',
        event = 'VimEnter',
        config = function()
            require('leap').set_default_keymaps()
        end,
        enabled = false,
    },
}
