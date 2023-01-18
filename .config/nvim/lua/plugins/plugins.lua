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
        'NTBBloodbath/rest.nvim',
        ft = 'http',
        config = function()
            vim.api.nvim_create_user_command('Rest', function()
                require('rest-nvim').run()
            end, {})
        end,
    },
    { 'soywod/himalaya', cmd = 'Himalaya' },
    { 'towolf/vim-helm', ft = 'helm' },
    { 'ellisonleao/glow.nvim', cmd = 'Glow' },
    {
        'jamestthompson3/nvim-remote-containers',
        cmd = { 'AttachToContainer', 'BuildImage', 'StartImage' },
        enabled = false,
    },
}
