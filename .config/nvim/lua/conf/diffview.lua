require('which-key').add {
    { '<Leader>c', group = 'Conflict', icon = '' },
}

local actions = require 'diffview.actions'
local keymaps = {
    disable_defaults = true,
    _shared = {
        {
            'n',
            'q',
            vim.cmd.tabclose,
            { desc = 'Close diffview' },
        },
        {
            'n',
            'gf',
            actions.goto_file_edit,
            { desc = 'Open file in prev tabpage' },
        },
    },
    view = {
        {
            'n',
            '<C-e>',
            actions.focus_files,
            { desc = 'Focus file panel', remap = true },
        },
        {
            'n',
            ']q',
            actions.select_next_entry,
            { desc = 'Next file', remap = true },
        },
        {
            'n',
            '[q',
            actions.select_prev_entry,
            { desc = 'Prev file', remap = true },
        },
        {
            'n',
            ']x',
            actions.next_conflict,
            { desc = 'Next conflict', remap = true },
        },
        {
            'n',
            '[x',
            actions.prev_conflict,
            { desc = 'Prev conflict', remap = true },
        },
        {
            'n',
            '<Leader>co',
            actions.conflict_choose 'ours',
            { desc = 'Choose OURS' },
        },
        {
            'n',
            '<Leader>ct',
            actions.conflict_choose 'theirs',
            { desc = 'Choose THEIRS' },
        },
        {
            'n',
            '<Leader>cb',
            actions.conflict_choose 'base',
            { desc = 'Choose BASE' },
        },
        {
            'n',
            '<Leader>ca',
            actions.conflict_choose 'all',
            { desc = 'Choose all' },
        },
        {
            'n',
            'dx',
            actions.conflict_choose 'none',
            { desc = 'Delete conflict region' },
        },
    },
    file_panel = {
        {
            'n',
            '?',
            actions.help 'file_panel',
            { desc = 'Open help panel' },
        },
        {
            'n',
            '<C-e>',
            actions.toggle_files,
            { desc = 'Toggle file panel', remap = true },
        },
        {
            'n',
            'R',
            actions.refresh_files,
            { desc = 'Refresh' },
        },
        {
            'n',
            'j',
            actions.next_entry,
            { desc = 'Next file' },
        },
        {
            'n',
            'k',
            actions.prev_entry,
            { desc = 'Prev file' },
        },
        {
            'n',
            '<cr>',
            actions.select_entry,
            { desc = 'Select file' },
        },
        {
            'n',
            's',
            actions.toggle_stage_entry,
            { desc = 'Stage / unstage file' },
        },
        {
            'n',
            'x',
            actions.restore_entry,
            { desc = 'Restore file' },
        },
        {
            'n',
            ']q',
            actions.select_next_entry,
            { desc = 'Next file', remap = true },
        },
        {
            'n',
            '[q',
            actions.select_prev_entry,
            { desc = 'Prev file', remap = true },
        },
        {
            'n',
            ']x',
            actions.next_conflict,
            { desc = 'Next conflict', remap = true },
        },
        {
            'n',
            '[x',
            actions.prev_conflict,
            { desc = 'Prev conflict', remap = true },
        },
        {
            'n',
            '<Leader>co',
            actions.conflict_choose_all 'ours',
            {
                desc = 'Choose OURS for whole file',
            },
        },
        {
            'n',
            '<Leader>ct',
            actions.conflict_choose_all 'theirs',
            { desc = 'Choose THEIRS for whole file' },
        },
        {
            'n',
            '<Leader>cb',
            actions.conflict_choose_all 'base',
            { desc = 'Choose BASE for whole file' },
        },
        {
            'n',
            '<Leader>ca',
            actions.conflict_choose_all 'all',
            { desc = 'Choose all for whole file' },
        },
        {
            'n',
            'dx',
            actions.conflict_choose_all 'none',
            { desc = 'Delete conflicts for whole file' },
        },
    },
    file_history_panel = {
        {
            'n',
            '?',
            actions.help 'file_history_panel',
            { desc = 'Help' },
        },
        {
            'n',
            'j',
            actions.select_next_entry,
            { desc = 'Next history entry' },
        },
        {
            'n',
            'k',
            actions.select_prev_entry,
            { desc = 'Prev history entry' },
        },
        {
            'n',
            ']q',
            actions.select_next_entry,
            { desc = 'Next history entry', remap = true },
        },
        {
            'n',
            '[q',
            actions.select_prev_entry,
            { desc = 'Prev history entry', remap = true },
        },
        {
            'n',
            'y',
            actions.copy_hash,
            { desc = 'Copy commit hash' },
        },
    },
    option_panel = {
        {
            'n',
            '<tab>',
            actions.select_entry,
            { desc = 'Change current option' },
        },
        {
            'n',
            'q',
            actions.close,
            { desc = 'Close panel' },
        },
        {
            'n',
            '?',
            actions.help 'option_panel',
            { desc = 'Help' },
        },
    },
    help_panel = {
        {
            'n',
            'q',
            actions.close,
            { desc = 'Close help' },
        },
        {
            'n',
            '<esc>',
            actions.close,
            { desc = 'Close help' },
        },
    },
}
vim.list_extend(keymaps.view, keymaps._shared)
vim.list_extend(keymaps.file_panel, keymaps._shared)
vim.list_extend(keymaps.file_history_panel, keymaps._shared)
keymaps._shared = nil

return { keymaps = keymaps }
