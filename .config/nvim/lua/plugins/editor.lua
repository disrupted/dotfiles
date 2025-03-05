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
        'AckslD/nvim-neoclip.lua',
        enabled = false,
        event = 'TextYankPost',
        keys = {
            {
                '\'',
                function()
                    require 'neoclip'
                    -- FIXME: open Snacks.picker
                end,
                desc = 'Neoclip',
            },
        },
        config = true,
    },
    {
        'stevearc/resession.nvim',
        keys = {
            {
                '<Leader>z',
                function()
                    require('conf.resession').load()
                end,
                desc = 'Restore session',
            },
        },
        init = function()
            vim.api.nvim_create_autocmd('VimLeavePre', {
                callback = function()
                    require('conf.resession').save()
                end,
                desc = 'Save session on quit',
            })
        end,
        opts = {
            ---@param bufnr integer
            ---@return boolean
            buf_filter = function(bufnr)
                local buftype = vim.bo[bufnr].buftype
                if buftype ~= '' and buftype ~= 'acwrite' then
                    return false
                end
                if vim.api.nvim_buf_get_name(bufnr) == '' then
                    return false
                end
                return vim.bo[bufnr].buflisted
            end,
            extensions = {
                dap = {},
            },
        },
    },
    {
        'ThePrimeagen/harpoon',
        branch = 'harpoon2',
        dependencies = { 'nvim-lua/plenary.nvim' },
        init = function()
            require('which-key').add { { ';', group = 'Harpoon', icon = '󰤱' } }
        end,
        keys = {
            {
                ';;',
                function()
                    local harpoon = require 'harpoon'
                    harpoon.ui:toggle_quick_menu(harpoon:list())
                end,
                desc = 'Menu',
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
                desc = 'Toggle Harpoon mark',
            },
            {
                ';a',
                function()
                    require('harpoon'):list():select(1)
                end,
                desc = 'Select 1',
            },
            {
                ';s',
                function()
                    require('harpoon'):list():select(2)
                end,
                desc = 'Select 2',
            },
            {
                ';d',
                function()
                    require('harpoon'):list():select(3)
                end,
                desc = 'Select 3',
            },
            {
                ';f',
                function()
                    require('harpoon'):list():select(4)
                end,
                desc = 'Select 4',
            },
            {
                ';g',
                function()
                    require('harpoon'):list():select(5)
                end,
                desc = 'Select 5',
            },
        },
        config = true,
    },
    { 'tpope/vim-abolish' },
}
