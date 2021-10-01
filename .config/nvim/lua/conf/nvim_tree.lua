local M = {}

function M.setup()
    local map = require('utils').map
    map('n', '<C-e>', '<cmd>NvimTreeToggle<CR>')
end

function M.config()
    vim.g.nvim_tree_ignore = { '.git', 'node_modules', '.cache' }

    vim.g.nvim_tree_show_icons = {
        git = 1,
        folders = 1,
        files = 1,
        folder_arrows = 0,
    }
    vim.g.nvim_tree_icons = {
        default = '',
        symlink = '',
        git_icons = {
            unstaged = '✗',
            staged = '✓',
            unmerged = '',
            renamed = '➜',
            untracked = '★',
            deleted = '',
            ignored = '◌',
        },
        folder_icons = {
            arrow_closed = '',
            arrow_open = '',
            default = '',
            open = '',
            empty = '',
            empty_open = '',
            symlink = '',
            symlink_open = '',
        },
        lsp = {
            hint = '',
            info = '',
            warning = '',
            error = '',
        },
    }

    local tree_cb = require('nvim-tree.config').nvim_tree_callback

    require('nvim-tree').setup {
        disable_netrw = true,
        hijack_netrw = true,
        open_on_setup = false,
        ignore_ft_on_setup = {},
        auto_close = true,
        open_on_tab = false,
        hijack_cursor = false,
        update_cwd = true,
        lsp_diagnostics = true,
        update_focused_file = {
            enable = true,
            update_cwd = false,
            ignore_list = {},
        },
        system_open = {
            cmd = nil,
            args = {
                {
                    key = { '<CR>', 'o', '<2-LeftMouse>', 'l' },
                    cb = tree_cb 'edit',
                },
                { key = { '<2-RightMouse>', '<C-]>' }, cb = tree_cb 'cd' },
                { key = '<C-v>', cb = tree_cb 'vsplit' },
                { key = '<C-x>', cb = tree_cb 'split' },
                { key = '<C-t>', cb = tree_cb 'tabnew' },
                { key = '<', cb = tree_cb 'prev_sibling' },
                { key = '>', cb = tree_cb 'next_sibling' },
                { key = 'P', cb = tree_cb 'parent_node' },
                { key = '<BS>', cb = tree_cb 'close_node' },
                { key = '<S-CR>', cb = tree_cb 'close_node' },
                { key = '<Tab>', cb = tree_cb 'preview' },
                { key = 'K', cb = tree_cb 'first_sibling' },
                { key = 'J', cb = tree_cb 'last_sibling' },
                { key = '!', cb = tree_cb 'toggle_ignored' },
                { key = '.', cb = tree_cb 'toggle_dotfiles' },
                { key = 'R', cb = tree_cb 'refresh' },
                { key = 'a', cb = tree_cb 'create' },
                { key = '<BS>', cb = tree_cb 'remove' },
                { key = 'r', cb = tree_cb 'rename' },
                { key = '<C-r>', cb = tree_cb 'full_rename' },
                { key = 'dd', cb = tree_cb 'cut' },
                { key = 'yy', cb = tree_cb 'copy' },
                { key = 'p', cb = tree_cb 'paste' },
                { key = 'y', cb = tree_cb 'copy_name' },
                { key = 'Y', cb = tree_cb 'copy_path' },
                {
                    key = 'gy',
                    cb = tree_cb 'copy_absolute_path',
                },
                { key = '[c', cb = tree_cb 'prev_git_item' },
                { key = ']c', cb = tree_cb 'next_git_item' },
                { key = '-', cb = tree_cb 'dir_up' },
                { key = 'q', cb = tree_cb 'close' },
                { key = '?', cb = tree_cb 'toggle_help' },
            },
        },

        view = {
            width = 30,
            side = 'left',
            auto_resize = false,
            mappings = {
                custom_only = false,
                list = {},
            },
        },
    }

    vim.cmd [[
      hi link NvimTreeIndentMarker Whitespace
      hi link NvimTreeFolderIcon NonText
    ]]

    -- lazy-loading
    require('nvim-tree.events').on_nvim_tree_ready(function()
        vim.cmd 'NvimTreeRefresh'
    end)
end

return M
