---@module 'lazy.types'
---@type LazySpec[]
return {
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
                    local list = harpoon:list()
                    local list_info = vim.iter(list.items):fold(
                        { max = 35 },
                        ---@param v HarpoonItem
                        function(acc, v)
                            local len = v.value:len()
                            acc.max = math.max(len, acc.max)
                            return acc
                        end
                    )
                    harpoon.ui:toggle_quick_menu(list, {
                        title = ' Harpoon ',
                        title_pos = 'center',
                        ui_width_ratio = 0.6,
                        ui_max_width = list_info.max + 5,
                        ui_fallback_width = 60,
                        height_in_lines = math.max(list:length(), 1),
                    })
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
