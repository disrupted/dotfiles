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
        ft = 'http',
        dependencies = { 'luarocks.nvim' },
        config = function()
            vim.api.nvim_create_user_command('Rest', function()
                require('rest-nvim').run()
            end, {})
        end,
    },
    { 'soywod/himalaya', cmd = 'Himalaya' },
    { 'ellisonleao/glow.nvim', cmd = 'Glow' },
    {
        'jamestthompson3/nvim-remote-containers',
        cmd = { 'AttachToContainer', 'BuildImage', 'StartImage' },
        enabled = false,
    },
}
