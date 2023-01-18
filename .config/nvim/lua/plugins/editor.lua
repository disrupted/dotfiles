return {
    {
        'nvim-telescope/telescope.nvim',
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
                    if vim.loop.fs_stat '.git' then
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

            -- telescope.load_extension 'notify'
        end,
        dependencies = {
            {
                'natecraddock/telescope-zf-native.nvim',
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
        },
    },
    {
        'kyazdani42/nvim-tree.lua',
        keys = {
            {
                '<C-e>',
                function()
                    require('nvim-tree').toggle()
                end,
            },
        },
        opts = function()
            local cb = require('nvim-tree.config').nvim_tree_callback
            return {
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
                        { key = 'x', cb = cb 'cut' },
                        { key = 'c', cb = cb 'copy' },
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
                    adaptive_size = true,
                    preserve_window_proportions = true,
                    width = 30,
                    side = 'left',
                    mappings = {
                        custom_only = false,
                        list = {
                            { key = '<C-e>', action = '' },
                        },
                    },
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

            vim.api.nvim_create_autocmd('BufEnter', {
                nested = true,
                callback = function()
                    if
                        #vim.api.nvim_list_wins() == 1
                        and vim.api.nvim_buf_get_name(0):match 'NvimTree_'
                            ~= nil
                    then
                        vim.cmd.quit()
                    end
                end,
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
        event = 'VimLeavePre',
        keys = {
            {
                '<leader>R',
                function()
                    require('persisted').load {}
                end,
            },
        },
        config = true,
    },
    {
        'famiu/bufdelete.nvim',
        keys = { { '<C-x>', '<cmd>Bdelete<CR>' } },
        cmd = { 'Bdelete', 'Bwipeout' },
    },
    {
        'ThePrimeagen/harpoon',
        keys = {
            {
                ';;',
                function()
                    require('harpoon.ui').toggle_quick_menu()
                end,
            },
            {
                'M',
                function()
                    require('harpoon.mark').toggle_file()
                end,
            },
            {
                ';a',
                function()
                    require('harpoon.ui').nav_file(1)
                end,
            },
            {
                ';s',
                function()
                    require('harpoon.ui').nav_file(2)
                end,
            },
            {
                ';d',
                function()
                    require('harpoon.ui').nav_file(3)
                end,
            },
            {
                ';f',
                function()
                    require('harpoon.ui').nav_file(4)
                end,
            },
            {
                ';g',
                function()
                    require('harpoon.ui').nav_file(5)
                end,
            },
        },
        config = true,
    },
}
