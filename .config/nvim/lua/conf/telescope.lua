local M = {}

function M.setup()
    local options = {
        shorten_path = false,
        height = 10,
        layout_strategy = 'horizontal',
        layout_config = { preview_width = 0.65 },
    }
    function _G.__telescope_files()
        -- Launch file search using Telescope
        -- if vim.fn.isdirectory(".git") then
        --     -- if in a git project, use :Telescope git_files
        --     require'telescope.builtin'.git_files(options)
        -- else
        -- otherwise, use :Telescope find_files
        require('telescope.builtin').find_files(options)
        -- end
    end
    function _G.__telescope_buffers()
        require('telescope.builtin').buffers {
            sort_lastused = true,
            ignore_current_buffer = true,
            sorter = require('telescope.sorters').get_substr_matcher(),
            shorten_path = true,
            height = 10,
            layout_strategy = 'horizontal',
            layout_config = { preview_width = 0.65 },
            show_all_buffers = true,
            color_devicons = true,
        }
    end
    function _G.__telescope_grep()
        require('telescope.builtin').live_grep {
            shorten_path = false,
            height = 10,
            layout_strategy = 'horizontal',
            layout_config = { preview_width = 0.4 },
        }
    end
    function _G.__telescope_commits()
        require('telescope.builtin').git_commits {
            height = 10,
            layout_strategy = 'horizontal',
            layout_config = { preview_width = 0.55 },
        }
    end
    local opts = { noremap = true, silent = true }
    vim.api.nvim_set_keymap(
        'n',
        '<Space>b',
        '<cmd>lua __telescope_buffers()<CR>',
        opts
    )
    vim.api.nvim_set_keymap(
        'n',
        '<C-f>',
        '<cmd>lua __telescope_files()<CR>',
        opts
    )
    vim.api.nvim_set_keymap('n', '<C-g>', '<cmd>Telescope git_status<CR>', opts)
    -- vim.api.nvim_set_keymap('n', '<Space>s',
    --                         "<cmd>lua require('telescope').extensions.frecency.frecency({layout_strategy = 'vertical'})<CR>",
    --    opts)
    vim.api.nvim_set_keymap(
        'n',
        '<Space>/',
        '<cmd>lua __telescope_grep()<CR>',
        opts
    )
    -- vim.api.nvim_set_keymap('n', '<Space>/',
    --                         '<cmd>lua require("telescope.builtin").grep_string { search = vim.fn.expand("<cword>") }<CR>',
    --                         opts)  -- grep for word under the cursor
    vim.api.nvim_set_keymap(
        'n',
        '<Space>h',
        '<cmd>lua require "telescope.builtin".help_tags(options)<CR>',
        opts
    )
    vim.api.nvim_set_keymap(
        'n',
        '<Space>c',
        '<cmd>lua __telescope_commits()<CR>',
        opts
    )
    vim.api.nvim_set_keymap(
        'n',
        ',pr',
        '<cmd>lua require "telescope.builtin".extensions.pull_request()<CR>',
        opts
    )
end

function M.config()
    vim.cmd [[packadd nvim-web-devicons]]
    local actions = require 'telescope.actions'
    local sorters = require 'telescope.sorters'
    local previewers = require 'telescope.previewers'

    require('telescope').setup {
        defaults = {
            prompt_prefix = ' ❯ ',
            mappings = {
                i = {
                    ['<ESC>'] = actions.close,
                    ['<C-j>'] = actions.move_selection_next,
                    ['<C-k>'] = actions.move_selection_previous,
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
        },
        extensions = {
            fzf = {
                override_generic_sorter = true,
                override_file_sorter = true,
                case_mode = 'smart_case',
            },
        },
    }
end

return M
