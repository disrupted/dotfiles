---@type LazeSpec[]
return {
    {
        'tiagovla/scope.nvim', -- tab-scoped buffers
        main = 'scope',
        module = 'scope',
        event = 'TabNew',
        opts = {},
    },
    {
        'stevearc/resession.nvim',
        main = 'resession',
        module = 'resession',
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
        config = function()
            local extensions = { dap = {} }
            -- only pull in the scope extension if scope.nvim was actually loaded
            if package.loaded['scope'] then
                extensions.scope = {}
            end
            require('resession').setup {
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
                    return true
                end,
                extensions = extensions,
            }
        end,
    },
    {
        'ThePrimeagen/harpoon',
        branch = 'harpoon2',
        main = 'harpoon',
        module = 'harpoon',
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
        config = function()
            require('harpoon').setup()
        end,
    },
    { 'tpope/vim-abolish' },
    {
        'disrupted/auto-save.nvim',
        main = 'auto-save',
        module = 'auto-save',
        event = { 'InsertLeave', 'TextChanged' },
        config = function()
            require('auto-save').setup {
                debounce_delay = 2000,
                trigger_events = {
                    immediate_save = {
                        'BufLeave',
                        'FocusLost',
                        'QuitPre',
                        'VimSuspend',
                    },
                    defer_save = {
                        'InsertLeave',
                        'TextChanged',
                        { 'User', pattern = 'VisualLeave' },
                    },
                    cancel_deferred_save = {
                        'InsertEnter',
                        { 'User', pattern = 'VisualEnter' },
                    },
                },
                condition = function(buf)
                    local mode = vim.api.nvim_get_mode().mode
                    if
                        vim.tbl_contains({ 'i', 'v', 'V', '\22', 'R' }, mode)
                    then
                        return false
                    end

                    if vim.bo[buf].buftype ~= '' then
                        return false
                    end

                    if
                        package.loaded.luasnip
                        and require('luasnip').in_snippet()
                    then
                        return false
                    end

                    return true
                end,
            }

            require('which-key').add {
                {
                    '<Leader>b',
                    '<cmd>ASToggle<cr>',
                    icon = { icon = '', hl = 'DiagnosticInfo' },
                    desc = 'Toggle autosave',
                },
            }

            local group = vim.api.nvim_create_augroup('autosave', {})
            vim.api.nvim_create_autocmd('User', {
                pattern = { 'AutoSaveEnable', 'AutoSaveDisable' },
                group = group,
                callback = function(args)
                    local enabled = args.match == 'AutoSaveEnable'
                    Snacks.notify(enabled and 'enabled' or 'disabled', {
                        id = 'autosave',
                        title = 'autosave',
                        history = false,
                        level = enabled and vim.log.levels.INFO
                            or vim.log.levels.WARN,
                    })
                end,
            })
            vim.api.nvim_create_autocmd('User', {
                pattern = 'AutoSaveWritePost',
                group = group,
                callback = function(args)
                    if args.data.saved_buffer ~= nil then
                        local filename =
                            vim.api.nvim_buf_get_name(args.data.saved_buffer)
                        Snacks.notify('saved ' .. filename, {
                            title = 'autosave',
                            level = vim.log.levels.DEBUG,
                        })
                    end
                end,
            })

            local visual_event_group =
                vim.api.nvim_create_augroup('visual_event', { clear = true })
            vim.api.nvim_create_autocmd('ModeChanged', {
                group = visual_event_group,
                pattern = { '*:[vV\x16]*' },
                callback = function()
                    vim.api.nvim_exec_autocmds(
                        'User',
                        { pattern = 'VisualEnter' }
                    )
                end,
            })
            vim.api.nvim_create_autocmd('ModeChanged', {
                group = visual_event_group,
                pattern = { '[vV\x16]*:*' },
                callback = function()
                    vim.api.nvim_exec_autocmds(
                        'User',
                        { pattern = 'VisualLeave' }
                    )
                end,
            })
        end,
    },
}
