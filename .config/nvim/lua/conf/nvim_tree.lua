local M = {}

function M.setup()
    vim.api.nvim_set_keymap('n', '<C-e>', '<cmd>NvimTreeToggle<CR>',
                            {noremap = true, silent = true})
end

function M.config()
    vim.g.nvim_tree_ignore = {'.git', 'node_modules', '.cache'}
    vim.g.nvim_tree_auto_open = 0 -- 0 by default, opens the tree when typing `nvim $DIR` or `nvim`
    vim.g.nvim_tree_auto_close = 1 -- 0 by default, closes the tree when it's the last window
    vim.g.nvim_tree_follow = 1 -- 0 by default, this option allows the cursor to be updated when entering a buffer
    vim.g.nvim_tree_indent_markers = 1 -- 0 by default, this option shows indent markers when folders are open
    vim.g.nvim_tree_git_hl = 1 -- 0 by default, will enable file highlight for git attributes (can be used without the icons).
    vim.g.nvim_tree_width = 30 -- 30 by default
    vim.g.nvim_tree_quit_on_open = 1 -- 0 by default, closes the tree when you open a file
    vim.g.nvim_tree_hide_dotfiles = 0 -- 0 by default, this option hides files and folders starting with a dot `.`
    vim.g.nvim_tree_tab_open = 0 -- 0 by default, will open the tree when entering a new tab and the tree was previously open
    vim.g.nvim_tree_allow_resize = 1 -- 0 by default, will not resize the tree when opening a file
    vim.g.nvim_tree_disable_keybindings = 0
    --  modify some of the key mappings
    local tree_cb = require'nvim-tree.config'.nvim_tree_callback
    vim.g.nvim_tree_bindings = {
        ['<CR>'] = tree_cb('edit'),
        ['o'] = tree_cb('edit'),
        ['l'] = tree_cb('edit'),
        ['<C-v>'] = tree_cb('vsplit'),
        ['<C-x>'] = tree_cb('split'),
        ['<C-t>'] = tree_cb('tabnew'),
        ['<S-CR>'] = tree_cb('close_node'),
        ['h'] = tree_cb('close_node'),
        ['!'] = tree_cb('toggle_ignored'),
        ['.'] = tree_cb('toggle_dotfiles'),
        ['R'] = tree_cb('refresh'),
        ['a'] = tree_cb('create'),
        ['<BS>'] = tree_cb('remove'),
        ['r'] = tree_cb('rename'),
        ['<C-r>'] = tree_cb('full_rename'),
        ['dd'] = tree_cb('cut'),
        ['yy'] = tree_cb('copy'),
        ['p'] = tree_cb('paste'),
        ['[c'] = tree_cb('prev_git_item'),
        [']c'] = tree_cb('next_git_item'),
        ['-'] = tree_cb('dir_up'),
        ['<C-]>'] = tree_cb('cd'),
        ['q'] = tree_cb('close')
    }

    vim.g.nvim_tree_icons = {
        default = ' ',
        symlink = ' ',
        git = {
            unstaged = '✗',
            staged = '✓',
            unmerged = '',
            renamed = '➜',
            untracked = '★'
        },
        folder = {default = '', open = ''}
    }

    vim.cmd([[
      hi link NvimTreeIndentMarker Whitespace
      hi link NvimTreeFolderIcon NonText
    ]])

    -- lazy-loading
    require'nvim-tree.events'.on_nvim_tree_ready(
        function() vim.cmd 'NvimTreeRefresh' end)
end

return M
