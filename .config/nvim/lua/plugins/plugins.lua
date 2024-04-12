return {
    'nvim-lua/plenary.nvim',
    { 'tpope/vim-repeat', event = 'VeryLazy' },
    { 'jghauser/mkdir.nvim', event = 'BufWritePre' },
    {
        'zsugabubus/crazy8.nvim',
        event = 'BufRead',
        enabled = false,
    },
    {
        'vhyrro/luarocks.nvim',
        priority = 1000,
        config = true,
    },
    {
        'rest-nvim/rest.nvim',
        main = 'rest-nvim',
        ft = 'http',
        keys = {
            {
                '<localleader>rr',
                '<cmd>Rest run<cr>',
                desc = 'Run request under the cursor',
            },
            {
                '<localleader>rl',
                '<cmd>Rest run last<cr>',
                desc = 'Re-run latest request',
            },
        },
        dependencies = { 'luarocks.nvim' },
        config = true,
    },
    { 'soywod/himalaya', cmd = 'Himalaya' },
    { 'ellisonleao/glow.nvim', cmd = 'Glow' },
    {
        'jamestthompson3/nvim-remote-containers',
        cmd = { 'AttachToContainer', 'BuildImage', 'StartImage' },
        enabled = false,
    },
}
