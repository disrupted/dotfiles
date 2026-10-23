---@type LazeSpec
return {
    'https://forge.barrettruth.com/barrettruth/ci.nvim',
    main = 'ci',
    module = 'ci',
    cmd = 'CI',
    init = function()
        require('which-key').add { { '<Leader>gc', group = 'CI' } }
    end,
    keys = {
        {
            '<Leader>gci',
            '<cmd>CI<CR>',
            desc = 'CI',
        },
    },
}
