return {
    {
        'nvim-telescope/telescope.nvim',
        enabled = false,
        cmd = 'Telescope',
        keys = {
            {
                '<leader><leader>',
                function()
                    require('telescope.builtin').buffers(
                        require('telescope.themes').get_dropdown {
                            previewer = false,
                            only_cwd = vim.fn.haslocaldir() == 1,
                            show_all_buffers = false,
                            sort_mru = true,
                            ignore_current_buffer = true,
                            sorter = require('telescope.sorters').get_substr_matcher(),
                            selection_strategy = 'closest',
                            path_display = { 'shorten' },
                            layout_strategy = 'center',
                            winblend = 0,
                            layout_config = { width = 70 },
                            color_devicons = true,
                        }
                    )
                end,
            },
            {
                '<C-f>',
                function()
                    -- Launch file search using Telescope
                    if vim.uv.fs_stat '.git' then
                        -- if in a git project, use :Telescope git_files
                        require('telescope.builtin').git_files()
                    else
                        -- otherwise, use :Telescope find_files
                        require('telescope.builtin').find_files()
                    end
                end,
            },
            {
                '<C-g>',
                function()
                    require('telescope.builtin').git_status()
                end,
            },
            {
                '<leader>/',
                function()
                    require('telescope.builtin').live_grep()
                end,
            },
            -- {
            --     '<leader>/',
            --     function()
            --         require('telescope.builtin').grep_string {
            --             search = vim.fn.expand '<cword>',
            --         }
            --     end,
            --     desc = 'grep for word under the cursor',
            -- },
            {
                '<leader>s',
                function()
                    require('telescope.builtin').lsp_dynamic_workspace_symbols()
                end,
            },
            {
                ',h',
                function()
                    require('telescope.builtin').help_tags()
                end,
            },
            {
                ',pr',
                function()
                    require('telescope.builtin').extensions.pull_request()
                end,
            },
        },
        config = function()
            local telescope = require 'telescope'
            local actions = require 'telescope.actions'
            local sorters = require 'telescope.sorters'
            local previewers = require 'telescope.previewers'
            local custom_pickers = require 'conf.telescope_custom_pickers'
            local action_state = require 'telescope.actions.state'

            local custom_actions = {}
            function custom_actions.qflist_multi_select(prompt_bufnr)
                local picker = action_state.get_current_picker(prompt_bufnr)
                local num_selections = #picker:get_multi_selection()

                if num_selections > 1 then
                    actions.send_selected_to_qflist(prompt_bufnr)
                else
                    actions.send_to_qflist(prompt_bufnr)
                end
                actions.open_qflist()
            end

            local default_options = {
                layout_strategy = 'horizontal',
                layout_config = { preview_width = 0.65 },
                sorter = telescope.extensions['zf-native'].native_zf_scorer(), -- HACK: override for lsp_dynamic_workspace_symbols because not set automatically
            }

            telescope.setup {
                defaults = {
                    prompt_prefix = ' ❯ ',
                    mappings = {
                        i = {
                            ['<ESC>'] = actions.close,
                            ['<C-j>'] = actions.move_selection_next,
                            ['<C-k>'] = actions.move_selection_previous,
                            ['<C-p>'] = require('telescope.actions.layout').toggle_preview,
                            ['<C-q>'] = custom_actions.qflist_multi_select,
                            ['<tab>'] = actions.toggle_selection
                                + actions.move_selection_next,
                            ['<s-tab>'] = actions.toggle_selection
                                + actions.move_selection_previous,
                        },
                        n = { ['<ESC>'] = actions.close },
                    },
                    file_ignore_patterns = {
                        '%.jpg',
                        '%.jpeg',
                        '%.png',
                        '%.svg',
                        '%.otf',
                        '%.ttf',
                    },
                    vimgrep_arguments = {
                        'rg',
                        '--color=never',
                        '--no-heading',
                        '--with-filename',
                        '--line-number',
                        '--column',
                        '--smart-case',
                        '--hidden',
                        '-g',
                        '!.git/',
                    },
                    file_sorter = sorters.get_fzy_sorter,
                    generic_sorter = sorters.get_fzy_sorter,
                    file_previewer = previewers.vim_buffer_cat.new,
                    grep_previewer = previewers.vim_buffer_vimgrep.new,
                    qflist_previewer = previewers.vim_buffer_qflist.new,
                    layout_strategy = 'flex',
                    winblend = 7,
                    set_env = { COLORTERM = 'truecolor' },
                    color_devicons = true,
                    scroll_strategy = 'limit',
                },
                pickers = {
                    live_grep = {
                        only_sort_text = true,
                        path_display = { 'shorten' },
                        mappings = {
                            i = {
                                ['<C-f>'] = custom_pickers.actions.set_folders,
                                ['<C-e>'] = custom_pickers.actions.set_extension,
                            },
                        },
                        layout_strategy = 'horizontal',
                        layout_config = { preview_width = 0.4 },
                    },
                    git_files = {
                        path_display = {},
                        hidden = true,
                        show_untracked = true,
                        layout_strategy = 'horizontal',
                        layout_config = { preview_width = 0.65 },
                    },
                    find_files = default_options,
                    git_status = default_options,
                    lsp_dynamic_workspace_symbols = default_options,
                    help_tags = default_options,
                },
                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = 'smart_case',
                    },
                    ['ui-select'] = {
                        require('telescope.themes').get_cursor { -- or get_dropdown
                            winblend = 0,
                            initial_mode = 'normal',
                        },
                    },
                },
            }
        end,
        dependencies = {
            {
                'natecraddock/telescope-zf-native.nvim',
                lazy = true,
                config = function()
                    require('telescope').load_extension 'zf-native'
                end,
            },
            {
                'nvim-telescope/telescope-ui-select.nvim',
                config = function()
                    require('telescope').load_extension 'ui-select'
                end,
            },
            {
                'nvim-telescope/telescope-github.nvim',
                config = function()
                    require('telescope').load_extension 'gh'
                end,
            },
            {
                'Marskey/telescope-sg',
                config = function()
                    require('telescope').load_extension 'ast_grep'
                end,
            },
        },
    },
    {
        'nvim-neo-tree/neo-tree.nvim',
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

            -- trivial
            -- vim.api.nvim_create_autocmd({ 'QuitPre' }, {
            --     callback = function()
            --         vim.cmd 'NvimTreeClose'
            --     end,
            -- })

            vim.api.nvim_create_autocmd('QuitPre', {
                callback = function()
                    local invalid_wins = {}
                    local wins = vim.api.nvim_list_wins()
                    for _, w in ipairs(wins) do
                        local bufname = vim.api.nvim_buf_get_name(
                            vim.api.nvim_win_get_buf(w)
                        )
                        if
                            bufname:match 'NvimTree_' ~= nil
                            or vim.api.nvim_win_get_config(w).relative ~= '' -- floating window
                        then
                            table.insert(invalid_wins, w)
                        end
                    end
                    if #invalid_wins == #wins - 1 then
                        -- Should quit, so we close all invalid windows.
                        for _, w in ipairs(invalid_wins) do
                            vim.api.nvim_win_close(w, true)
                        end
                    end
                end,
                desc = 'Close NvimTree if last window',
            })
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
                    require('telescope').extensions.neoclip.default()
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
