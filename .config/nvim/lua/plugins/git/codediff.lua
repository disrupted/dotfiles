local icons = require('conf.icons')

---@type LazeSpec
return {
    'esmuellert/codediff.nvim',
    main = 'codediff',
    module = 'codediff',
    cmd = 'CodeDiff',
    init = function()
        require('which-key').add({
            {
                '<Leader>gd',
                group = 'Codediff',
                icon = icons.git.diff,
            },
        })
    end,
    keys = {
        {
            '<Leader>gdr',
            function()
                vim.ui.input({ prompt = 'Codediff Revision' }, function(revision)
                    if revision and revision ~= '' then
                        vim.cmd('CodeDiff ' .. revision)
                    else
                        vim.cmd('CodeDiff') -- No revision = git status
                    end
                end)
            end,
            desc = 'Revision',
        },
        {
            '<Leader>gdf',
            '<cmd>CodeDiff history HEAD~20 %<CR>',
            desc = 'File history',
        },
        {
            '<Leader>gdb',
            function()
                vim.cmd({ cmd = 'CodeDiff', args = { 'origin/HEAD...HEAD' } })
                -- require('gitsigns').change_base('origin/HEAD', true)
            end,
            desc = 'Review branch changes',
        },
    },
    config = function()
        require('codediff').setup({
            highlights = {
                line_insert = 'OneDiffAddLine',
                line_delete = 'OneDiffDeleteLine',
                char_insert = 'OneDiffAddText',
                char_delete = 'OneDiffDeleteText',
            },
            diff = {
                disable_inlay_hints = true,
                original_position = 'left',
                conflict_ours_position = 'right',
            },
            explorer = {
                position = 'left',
                width = 40,
                view_mode = 'tree',
                initial_focus = 'explorer',
                indent_markers = true,
                focus_on_select = false,
            },
            history = {
                position = 'bottom',
                height = 15,
                initial_focus = 'history',
                view_mode = 'list',
            },
            keymaps = {
                view = {
                    quit = 'q',
                    toggle_explorer = '<C-e>',
                    next_hunk = ']g',
                    prev_hunk = '[g',
                    next_file = ']q',
                    prev_file = '[q',
                    diff_get = 'do',
                    diff_put = 'dp',
                    toggle_stage = 's',
                },
                explorer = {
                    select = '<CR>',
                    hover = 'K',
                    refresh = 'R',
                    toggle_view_mode = 'i',
                    stage_all = 'S',
                    unstage_all = 'U',
                    restore = 'x',
                },
                history = {
                    select = '<CR>',
                    toggle_view_mode = 'i',
                },
                conflict = {
                    accept_incoming = '<LocalLeader>xt', -- theirs
                    accept_current = '<LocalLeader>xo', -- ours
                    accept_both = '<LocalLeader>xa', -- all
                    discard = '<LocalLeader>xb', -- discard both
                    next_conflict = ']x',
                    prev_conflict = '[x',
                    diffget_incoming = '2do',
                    diffget_current = '3do',
                },
            },
        })
    end,
}
