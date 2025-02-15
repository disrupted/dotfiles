---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'nvim-neo-tree/neo-tree.nvim',
        enabled = false,
        branch = 'v3.x',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-tree/nvim-web-devicons',
            'MunifTanjim/nui.nvim',
            'nvim-lsp-file-operations',
        },
        cmd = 'Neotree',
        keys = {
            { '<C-e>', '<cmd>Neotree toggle<CR>' },
        },
        init = function()
            vim.api.nvim_create_autocmd('BufEnter', {
                group = vim.api.nvim_create_augroup(
                    'NeoTreeInit',
                    { clear = true }
                ),
                callback = function()
                    local path = vim.fn.expand '%:p'
                    local stat = vim.uv.fs_stat(path)
                    if stat and stat.type == 'directory' then
                        vim.cmd('Neotree current dir=' .. path)
                        -- neo-tree is loaded now, delete the init autocmd
                        vim.api.nvim_clear_autocmds { group = 'NeoTreeInit' }
                    end
                end,
                desc = 'Open Neotree when launching Neovim with a directory',
            })
        end,
        opts = {
            filesystem = {
                follow_current_file = { enabled = true },
                hijack_netrw_behavior = 'open_current',
                filtered_items = {
                    always_show = {
                        '.github',
                    },
                    always_show_by_pattern = {
                        '.env*',
                    },
                    never_show = {
                        '.DS_Store',
                        '__pycache__',
                        '.mypy_cache',
                        '.pytest_cache',
                        '.ruff_cache',
                    },
                },
            },
            default_component_configs = {
                git_status = {
                    symbols = {
                        untracked = '*',
                        ignored = '',
                        unstaged = '󰄱',
                        staged = '',
                        conflict = '',
                    },
                },
            },
        },
    },
    {
        'nvim-tree/nvim-tree.lua',
        -- enabled = false,
        dependencies = {
            'nvim-lsp-file-operations',
        },
        cmd = { 'NvimTreeOpen', 'NvimTreeToggle' },
        -- keys = {
        --     {
        --         '<C-e>',
        --         function()
        --             require('nvim-tree.api').tree.toggle()
        --         end,
        --     },
        -- },
        opts = function()
            return {
                on_attach = function(bufnr)
                    local api = require 'nvim-tree.api'
                    local opts = function(desc)
                        return {
                            desc = 'nvim-tree: ' .. desc,
                            buffer = bufnr,
                            noremap = true,
                            silent = true,
                            nowait = true,
                        }
                    end
                    vim.keymap.set(
                        'n',
                        '<C-]>',
                        api.tree.change_root_to_node,
                        opts 'CD'
                    )
                    vim.keymap.set(
                        'n',
                        '<C-k>',
                        api.node.show_info_popup,
                        opts 'Info'
                    )
                    vim.keymap.set(
                        'n',
                        '<C-r>',
                        api.fs.rename_sub,
                        opts 'Rename: Omit Filename'
                    )
                    vim.keymap.set(
                        'n',
                        '<C-t>',
                        api.node.open.tab,
                        opts 'Open: New Tab'
                    )
                    vim.keymap.set(
                        'n',
                        '<C-v>',
                        api.node.open.vertical,
                        opts 'Open: Vertical Split'
                    )
                    vim.keymap.set(
                        'n',
                        '<C-x>',
                        api.node.open.horizontal,
                        opts 'Open: Horizontal Split'
                    )
                    vim.keymap.set(
                        'n',
                        '<BS>',
                        api.node.navigate.parent_close,
                        opts 'Close Directory'
                    )
                    vim.keymap.set('n', '<CR>', api.node.open.edit, opts 'Open')
                    vim.keymap.set(
                        'n',
                        '<Tab>',
                        api.node.open.preview,
                        opts 'Open Preview'
                    )
                    vim.keymap.set(
                        'n',
                        '>',
                        api.node.navigate.sibling.next,
                        opts 'Next Sibling'
                    )
                    vim.keymap.set(
                        'n',
                        '<',
                        api.node.navigate.sibling.prev,
                        opts 'Previous Sibling'
                    )
                    vim.keymap.set(
                        'n',
                        '.',
                        api.node.run.cmd,
                        opts 'Run Command'
                    )
                    vim.keymap.set(
                        'n',
                        '-',
                        api.tree.change_root_to_parent,
                        opts 'Up'
                    )
                    vim.keymap.set('n', 'a', api.fs.create, opts 'Create')
                    vim.keymap.set(
                        'n',
                        'bmv',
                        api.marks.bulk.move,
                        opts 'Move Bookmarked'
                    )
                    vim.keymap.set(
                        'n',
                        'B',
                        api.tree.toggle_no_buffer_filter,
                        opts 'Toggle No Buffer'
                    )
                    vim.keymap.set('n', 'c', api.fs.copy.node, opts 'Copy')
                    vim.keymap.set(
                        'n',
                        'C',
                        api.tree.toggle_git_clean_filter,
                        opts 'Toggle Git Clean'
                    )
                    vim.keymap.set(
                        'n',
                        '[c',
                        api.node.navigate.git.prev,
                        opts 'Prev Git'
                    )
                    vim.keymap.set(
                        'n',
                        ']c',
                        api.node.navigate.git.next,
                        opts 'Next Git'
                    )
                    vim.keymap.set('n', 'd', api.fs.remove, opts 'Delete')
                    vim.keymap.set('n', 'D', api.fs.trash, opts 'Trash')
                    vim.keymap.set(
                        'n',
                        'E',
                        api.tree.expand_all,
                        opts 'Expand All'
                    )
                    vim.keymap.set(
                        'n',
                        'e',
                        api.fs.rename_basename,
                        opts 'Rename: Basename'
                    )
                    vim.keymap.set(
                        'n',
                        ']e',
                        api.node.navigate.diagnostics.next,
                        opts 'Next Diagnostic'
                    )
                    vim.keymap.set(
                        'n',
                        '[e',
                        api.node.navigate.diagnostics.prev,
                        opts 'Prev Diagnostic'
                    )
                    vim.keymap.set(
                        'n',
                        'F',
                        api.live_filter.clear,
                        opts 'Clean Filter'
                    )
                    vim.keymap.set(
                        'n',
                        'f',
                        api.live_filter.start,
                        opts 'Filter'
                    )
                    vim.keymap.set('n', 'g?', api.tree.toggle_help, opts 'Help')
                    vim.keymap.set(
                        'n',
                        'gy',
                        api.fs.copy.absolute_path,
                        opts 'Copy Absolute Path'
                    )
                    vim.keymap.set(
                        'n',
                        '.',
                        api.tree.toggle_hidden_filter,
                        opts 'Toggle Dotfiles'
                    )
                    vim.keymap.set(
                        'n',
                        '!',
                        api.tree.toggle_gitignore_filter,
                        opts 'Toggle Git Ignore'
                    )
                    vim.keymap.set(
                        'n',
                        'J',
                        api.node.navigate.sibling.last,
                        opts 'Last Sibling'
                    )
                    vim.keymap.set(
                        'n',
                        'K',
                        api.node.navigate.sibling.first,
                        opts 'First Sibling'
                    )
                    vim.keymap.set(
                        'n',
                        'm',
                        api.marks.toggle,
                        opts 'Toggle Bookmark'
                    )
                    vim.keymap.set('n', 'o', api.node.open.edit, opts 'Open')
                    vim.keymap.set(
                        'n',
                        'O',
                        api.node.open.no_window_picker,
                        opts 'Open: No Window Picker'
                    )
                    vim.keymap.set('n', 'p', api.fs.paste, opts 'Paste')
                    vim.keymap.set(
                        'n',
                        'P',
                        api.node.navigate.parent,
                        opts 'Parent Directory'
                    )
                    vim.keymap.set('n', 'q', api.tree.close, opts 'Close')
                    vim.keymap.set('n', 'r', api.fs.rename, opts 'Rename')
                    vim.keymap.set('n', 'R', api.tree.reload, opts 'Refresh')
                    vim.keymap.set(
                        'n',
                        's',
                        api.node.run.system,
                        opts 'Run System'
                    )
                    vim.keymap.set(
                        'n',
                        'S',
                        api.tree.search_node,
                        opts 'Search'
                    )
                    vim.keymap.set(
                        'n',
                        'U',
                        api.tree.toggle_custom_filter,
                        opts 'Toggle Hidden'
                    )
                    vim.keymap.set(
                        'n',
                        'W',
                        api.tree.collapse_all,
                        opts 'Collapse'
                    )
                    vim.keymap.set('n', 'x', api.fs.cut, opts 'Cut')
                    vim.keymap.set(
                        'n',
                        'y',
                        api.fs.copy.filename,
                        opts 'Copy Name'
                    )
                    vim.keymap.set(
                        'n',
                        'Y',
                        api.fs.copy.relative_path,
                        opts 'Copy Relative Path'
                    )
                    vim.keymap.set(
                        'n',
                        '<2-LeftMouse>',
                        api.node.open.edit,
                        opts 'Open'
                    )
                    vim.keymap.set(
                        'n',
                        '<2-RightMouse>',
                        api.tree.change_root_to_node,
                        opts 'CD'
                    )
                end,
                disable_netrw = true,
                hijack_netrw = true,
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
                    severity = {
                        min = vim.diagnostic.severity.WARN,
                    },
                },
                update_focused_file = {
                    enable = true,
                    update_cwd = false,
                    ignore_list = {},
                },
                view = {
                    adaptive_size = true,
                    preserve_window_proportions = true,
                    width = 30,
                    side = 'left',
                },
                renderer = {
                    icons = {
                        show = {
                            git = true,
                            folder = true,
                            file = true,
                            folder_arrow = false,
                        },
                        glyphs = {
                            default = '',
                            symlink = '',
                            git = {
                                unstaged = '✗',
                                staged = '✓',
                                unmerged = '',
                                renamed = '➜',
                                untracked = '★',
                                deleted = '',
                                ignored = '◌',
                            },
                            folder = {
                                arrow_closed = '',
                                arrow_open = '',
                                default = '',
                                open = '',
                                empty = '',
                                empty_open = '',
                                symlink = '',
                                symlink_open = '',
                            },
                        },
                    },
                },
                filters = {
                    dotfiles = false,
                    -- custom = { '.git', 'node_modules', '.cache' },
                },
                actions = {
                    open_file = {
                        resize_window = true,
                    },
                },
            }
        end,
        config = function(_, opts)
            require('nvim-tree').setup(opts)

            vim.api.nvim_set_hl(
                0,
                'NvimTreeIndentMarker',
                { link = 'Whitespace' }
            )
            vim.api.nvim_set_hl(0, 'NvimTreeFolderIcon', { link = 'NonText' })
        end,
    },
    {
        'AckslD/nvim-neoclip.lua',
        event = 'TextYankPost',
        keys = {
            {
                '\'',
                function()
                    require 'neoclip'
                    -- FIXME: open Snacks.picker
                end,
            },
        },
        config = true,
    },
    { 'tversteeg/registers.nvim', lazy = true },
    {
        'olimorris/persisted.nvim',
        enabled = false,
        lazy = false,
        opts = { autoload = true },
    },
    {
        'jedrzejboczar/possession.nvim',
        enabled = true,
        event = 'UIEnter',
        opts = {
            -- autoload = true,
            commands = {
                save = 'SessionSave',
                load = 'SessionLoad',
                save_cwd = 'SessionSaveCwd',
                load_cwd = 'SessionLoadCwd',
                rename = 'SessionRename',
                close = 'SessionClose',
                delete = 'SessionDelete',
                show = 'SessionShow',
                list = 'SessionList',
                list_cwd = 'SessionListCwd',
                migrate = 'SessionMigrate',
            },
        },
    },
    {
        'ThePrimeagen/harpoon',
        branch = 'harpoon2',
        dependencies = { 'nvim-lua/plenary.nvim' },
        keys = {
            {
                ';;',
                function()
                    local harpoon = require 'harpoon'
                    harpoon.ui:toggle_quick_menu(harpoon:list())
                end,
            },
            {
                'M',
                function()
                    local harpoon = require 'harpoon'
                    local list = harpoon:list()
                    local item = list.config.create_list_item(list.config)

                    if not list:get_by_value(item.value) then
                        list:add(item)
                    else
                        list:remove(item)
                    end
                end,
                desc = 'Toggle file',
            },
            {
                ';a',
                function()
                    require('harpoon'):list():select(1)
                end,
            },
            {
                ';s',
                function()
                    require('harpoon'):list():select(2)
                end,
            },
            {
                ';d',
                function()
                    require('harpoon'):list():select(3)
                end,
            },
            {
                ';f',
                function()
                    require('harpoon'):list():select(4)
                end,
            },
            {
                ';g',
                function()
                    require('harpoon'):list():select(5)
                end,
            },
        },
        config = true,
    },
    { 'tpope/vim-abolish' },
}
