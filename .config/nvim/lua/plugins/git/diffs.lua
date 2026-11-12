---@type LazeSpec
return {
    'barrettruth/diffs.nvim',
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
        require('which-key').add({ { '<Leader>gx', group = 'Conflict' } })

        ---@module 'diffs'
        ---@type diffs.Config
        vim.g.diffs = {
            view = {
                prefix = false,
            },
            integrations = {
                neogit = true,
            },
            highlights = {
                warn_max_lines = false,
                blend_alpha = 0.6,
            },
        }

        vim.api.nvim_create_autocmd('FileType', {
            group = vim.api.nvim_create_augroup(
                'diffs_extra_filetypes',
                { clear = true }
            ),
            pattern = 'diff',
            callback = function(event)
                require('diffs').attach(event.buf)
            end,
        })
    end,
    config = function()
        local function set_highlights()
            vim.api.nvim_set_hl(0, 'DiffsAddText', { link = 'OneDiffAddText' })
            vim.api.nvim_set_hl(0, 'DiffsDeleteText', { link = 'OneDiffDeleteText' })
        end
        vim.api.nvim_create_autocmd('ColorScheme', {
            group = vim.api.nvim_create_augroup('diffs_highlights', { clear = true }),
            callback = function()
                -- diffs.nvim recomputes its groups on ColorScheme, so apply ours after
                vim.schedule(set_highlights)
            end,
        })
        vim.schedule(set_highlights)

        vim.api.nvim_create_autocmd('User', {
            pattern = 'DiffsConflictResolved',
            callback = function()
                Snacks.notify('all conflicts resolved!', { title = '' })
            end,
        })
    end,
}
