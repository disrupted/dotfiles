local M = {}

function M.setup()
    vim.keymap.set('n', '<C-e>', function()
        require('nvim-tree').toggle()
    end)
end

function M.config()
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
    }

    local cb = require('nvim-tree.config').nvim_tree_callback

    require('nvim-tree').setup {
        disable_netrw = true,
        hijack_netrw = true,
        open_on_setup = false,
        ignore_ft_on_setup = {},
        open_on_tab = false,
        hijack_cursor = false,
        update_cwd = true,
        diagnostics = {
            enable = true,
            icons = {
                hint = '',
                info = '',
                warning = '',
                error = '',
            },
        },
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
                    cb = cb 'edit',
                },
                { key = { '<2-RightMouse>' }, cb = cb 'cd' },
                { key = '<C-v>', cb = cb 'vsplit' },
                { key = '<C-x>', cb = cb 'split' },
                { key = '<C-t>', cb = cb 'tabnew' },
                { key = '<', cb = cb 'prev_sibling' },
                { key = '>', cb = cb 'next_sibling' },
                { key = 'P', cb = cb 'parent_node' },
                { key = '<BS>', cb = cb 'close_node' },
                { key = '<S-CR>', cb = cb 'close_node' },
                { key = '<Tab>', cb = cb 'preview' },
                { key = 'K', cb = cb 'first_sibling' },
                { key = 'J', cb = cb 'last_sibling' },
                { key = '!', cb = cb 'toggle_ignored' },
                { key = '.', cb = cb 'toggle_dotfiles' },
                { key = 'R', cb = cb 'refresh' },
                { key = 'a', cb = cb 'create' },
                { key = '<BS>', cb = cb 'remove' },
                { key = 'r', cb = cb 'rename' },
                { key = '<C-r>', cb = cb 'full_rename' },
                { key = 'dd', cb = cb 'cut' },
                { key = 'yy', cb = cb 'copy' },
                { key = 'p', cb = cb 'paste' },
                { key = 'y', cb = cb 'copy_name' },
                { key = 'Y', cb = cb 'copy_path' },
                {
                    key = 'gy',
                    cb = cb 'copy_absolute_path',
                },
                { key = '[c', cb = cb 'prev_git_item' },
                { key = ']c', cb = cb 'next_git_item' },
                { key = '-', cb = cb 'dir_up' },
                { key = 'q', cb = cb 'close' },
                { key = '?', cb = cb 'toggle_help' },
            },
        },
        view = {
            width = 30,
            side = 'left',
            mappings = {
                custom_only = false,
                list = {
                    { key = '<C-e>', action = '' },
                },
            },
        },
        filters = {
            custom = { '.git', 'node_modules', '.cache' },
        },
        actions = {
            open_file = {
                resize_window = true,
            },
        },
    }

    vim.api.nvim_set_hl(0, 'NvimTreeIndentMarker', { link = 'Whitespace' })
    vim.api.nvim_set_hl(0, 'NvimTreeFolderIcon', { link = 'NonText' })

    vim.api.nvim_create_autocmd('BufEnter', {
        nested = true,
        callback = function()
            if
                #vim.api.nvim_list_wins() == 1
                and vim.api.nvim_buf_get_name(0):match 'NvimTree_' ~= nil
            then
                vim.cmd 'quit'
            end
        end,
    })
end

return M
