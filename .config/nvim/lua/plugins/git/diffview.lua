local icons = require('conf.icons')

---@type LazeSpec
return {
    'sindrets/diffview.nvim',
    enabled = false, -- disables in favor of codediff.nvim
    main = 'diffview',
    module = 'diffview',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
    init = function()
        require('which-key').add({
            {
                '<Leader>gD',
                group = 'Diffview',
                icon = icons.git.diff,
            },
        })
    end,
    keys = {
        {
            '<Leader>gDr',
            function()
                vim.ui.input({ prompt = 'Diffview Revision' }, function(revision)
                    local cmd = 'DiffviewOpen'
                    if revision then
                        cmd = cmd .. ' ' .. revision
                    end
                    vim.cmd(cmd .. ' -- .')
                end)
            end,
            desc = 'Revision',
        },
        {
            '<Leader>gDf',
            '<cmd>DiffviewFileHistory %<CR>',
            desc = 'File history',
        },
        {
            '<Leader>gDb',
            function()
                vim.cmd.DiffviewOpen('origin/HEAD...HEAD -- .')
                -- require('gitsigns').change_base('origin/HEAD', true)
            end,
            desc = 'Review branch changes',
        },
    },
    config = function()
        ---@module 'diffview.config'
        ---@type DiffviewConfig
        local opts = {
            enhanced_diff_hl = true,
            default_args = {
                DiffviewOpen = { '--untracked-files=no', '--imply-local' },
                DiffviewFileHistory = { '--base=LOCAL', '--no-merges' },
            },
            view = {
                default = { winbar_info = true },
                file_history = { winbar_info = true },
                merge_tool = {
                    -- layout = 'diff4_mixed',
                    disable_diagnostics = true,
                    winbar_info = true,
                },
            },
            file_panel = {
                win_config = {
                    win_opts = { statuscolumn = '', signcolumn = 'auto' },
                },
            },
            hooks = {
                diff_buf_win_enter = function(_bufnr, winid, _ctx)
                    -- Turn off cursor line for diffview windows because of bg conflict
                    -- https://github.com/neovim/neovim/issues/9800
                    vim.wo[winid].cursorlineopt = 'number'
                    vim.wo[winid].wrap = false
                    vim.wo[winid].statuscolumn = ''
                end,
            },
            keymaps = require('conf.diffview').keymaps,
        }
        require('diffview').setup(opts)
    end,
}
