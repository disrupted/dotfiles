local M = {}

function M.setup()
    local builtins = require('telescope.builtin')
    function _G.__telescope_files()
        -- Launch file search using Telescope
        -- if vim.fn.isdirectory(".git") then
        --     -- if in a git project, use :Telescope git_files
        --     builtins.git_files(options)
        -- else
        -- otherwise, use :Telescope find_files
        builtins.find_files(options)
        -- end
    end
    function _G.__telescope_buffers()
        builtins.buffers({
            shorten_path = false,
            height = 10,
            layout_strategy = 'horizontal',
            layout_config = {preview_width = 0.65},
            show_all_buffers = true,
            color_devicons = true
        })
    end
    function _G.__telescope_grep()
        builtins.live_grep({
            shorten_path = false,
            height = 10,
            layout_strategy = 'horizontal',
            layout_config = {preview_width = 0.4}
        })
    end
    function _G.__telescope_commits()
        builtins.git_commits({
            height = 10,
            layout_strategy = 'horizontal',
            layout_config = {preview_width = 0.55}
        })
    end
    -- vim.api.nvim_set_keymap('n', '<Space>b', '<cmd>Buffers<CR>', {noremap = true, silent = true})
    vim.api.nvim_set_keymap('n', '<Space>b',
                            '<cmd>lua __telescope_buffers()<CR>',
                            {noremap = true, silent = true})
    vim.api.nvim_set_keymap('n', '<C-f>', '<cmd>lua __telescope_files()<CR>',
                            {noremap = true, silent = true})
    vim.api.nvim_set_keymap('n', '<Space>s',
                            "<cmd>lua require('telescope').extensions.frecency.frecency({layout_strategy = 'vertical'})<CR>",
                            {noremap = true, silent = true})
    vim.api.nvim_set_keymap('n', '<Space>g', '<cmd>lua __telescope_grep()<CR>',
                            {noremap = true, silent = true})
    vim.api.nvim_set_keymap('n', '<Space>h',
                            "<cmd>lua require('telescope.builtin').help_tags(options)<CR>",
                            {noremap = true, silent = true})
    vim.api.nvim_set_keymap('n', '<Space>c',
                            '<cmd>lua __telescope_commits()<CR>',
                            {noremap = true, silent = true})
end

function M.config()
    local actions = require('telescope.actions')
    local sorters = require('telescope.sorters')
    local previewers = require('telescope.previewers')

    require'telescope'.setup {
        defaults = {
            prompt_prefix = ' ❯',
            mappings = {i = {["<ESC>"] = actions.close}},
            -- file_ignore_patterns = {"%.jpg", "%.jpeg", "%.png", "%.otf", "%.ttf"},
            file_sorter = sorters.get_fzy_sorter,
            generic_sorter = sorters.get_fzy_sorter,
            file_previewer = previewers.vim_buffer_cat.new,
            grep_previewer = previewers.vim_buffer_vimgrep.new,
            qflist_previewer = previewers.vim_buffer_qflist.new,
            layout_strategy = 'flex',
            winblend = 7,
            set_env = {COLORTERM = "truecolor"},
            color_devicons = true
        }
    }

    local options = {
        shorten_path = false,
        height = 10,
        layout_strategy = 'horizontal',
        layout_config = {preview_width = 0.65}
    }
end

return M