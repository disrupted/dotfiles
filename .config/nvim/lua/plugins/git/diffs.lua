---@type LazeSpec
return {
    'https://forge.barrettruth.com/barrettruth/diffs.nvim',
    main = 'diffs',
    module = 'diffs',
    lazy = false,
    keys = {
        {
            '<Leader>gxo',
            '<Plug>(diffs-conflict-ours)',
            desc = 'Pick ours',
        },
        {
            '<Leader>gxt',
            '<Plug>(diffs-conflict-theirs)',
            desc = 'Pick theirs',
        },
        {
            '<Leader>gxa',
            '<Plug>(diffs-conflict-both)',
            desc = 'Pick all',
        },
        {
            '<Leader>gx0',
            '<Plug>(diffs-conflict-none)',
            desc = 'Pick none',
        },
        {
            '[x',
            '<Plug>(diffs-conflict-prev)',
            desc = 'Prev conflict',
        },
        {
            ']x',
            '<Plug>(diffs-conflict-next)',
            desc = 'Next conflict',
        },
    },
    init = function()
        require('which-key').add { { '<Leader>gx', group = 'Conflict' } }

        ---@module 'diffs'
        ---@type diffs.Config
        vim.g.diffs = {
            view = {
                prefix = false,
            },
            integrations = {
                neogit = true,
            },
            extra_filetypes = { 'diff' },
            conflict = {
                keymaps = {
                    ours = '<Leader>gxo',
                    theirs = '<Leader>gxt',
                    both = '<Leader>gxa',
                    none = '<Leader>gx0',
                    next = ']x',
                    prev = '[x',
                },
            },
            highlights = {
                warn_max_lines = false,
                blend_alpha = 0.6,
                intra = {
                    enabled = true,
                    algorithm = 'vscode',
                },
                overrides = {
                    DiffsAddText = { link = 'OneDiffAddText' },
                    DiffsDeleteText = { link = 'OneDiffDeleteText' },
                },
            },
        }
    end,
    config = function()
        vim.api.nvim_create_autocmd('User', {
            pattern = 'DiffsConflictResolved',
            callback = function()
                Snacks.notify('all conflicts resolved!', { title = '' })
            end,
        })
    end,
}
