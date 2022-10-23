local M = {}

function M.setup()
    local function telescope_buffers()
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
    end
    -- local function telescope_commits()
    --     require('telescope.builtin').git_commits {
    --         layout_strategy = 'horizontal',
    --         layout_config = { preview_width = 0.55 },
    --     }
    -- end
    vim.keymap.set('n', '<leader><leader>', function()
        telescope_buffers()
    end)
    vim.keymap.set('n', '<C-f>', function()
        -- Launch file search using Telescope
        if vim.loop.fs_stat '.git' then
            -- if in a git project, use :Telescope git_files
            require('telescope.builtin').git_files()
        else
            -- otherwise, use :Telescope find_files
            require('telescope.builtin').find_files()
        end
    end)
    vim.keymap.set('n', '<C-g>', function()
        require('telescope.builtin').git_status()
    end)
    -- vim.keymap.set('n', '<leader>s', function()
    --     require('telescope').extensions.frecency.frecency {
    --         layout_strategy = 'vertical',
    --     }
    -- end)
    vim.keymap.set('n', '<leader>/', function()
        require('telescope.builtin').live_grep()
    end)
    -- vim.keymap.set('n', '<leader>/', function()
    --     require('telescope.builtin').grep_string {
    --         search = vim.fn.expand '<cword>',
    --     }
    -- end) -- grep for word under the cursor
    vim.keymap.set('n', '<leader>s', function()
        require('telescope.builtin').lsp_dynamic_workspace_symbols()
    end)
    vim.keymap.set('n', ',h', function()
        require('telescope.builtin').help_tags()
    end)
    -- vim.keymap.set('n', '<leader>c', function()
    --     __telescope_commits()
    -- end)
    vim.keymap.set('n', ',pr', function()
        require('telescope.builtin').extensions.pull_request()
    end)
end

function M.config()
    local telescope = require 'telescope'
    local actions = require 'telescope.actions'
    local sorters = require 'telescope.sorters'
    local previewers = require 'telescope.previewers'
    local custom_pickers = require 'conf.telescope_custom_pickers'
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
end

return M
