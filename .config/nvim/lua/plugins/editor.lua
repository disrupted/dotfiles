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
