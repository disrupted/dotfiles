---@type LazeSpec
return {
    'disrupted/auto-save.nvim',
    main = 'auto-save',
    module = 'auto-save',
    event = { 'InsertLeave', 'TextChanged' },
    config = function()
        require('auto-save').setup({
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
                if vim.tbl_contains({ 'i', 'v', 'V', '\22', 'R' }, mode) then
                    return false
                end

                if vim.bo[buf].buftype ~= '' then
                    return false
                end

                if package.loaded.luasnip and require('luasnip').in_snippet() then
                    return false
                end

                return true
            end,
        })

        require('which-key').add({
            {
                '<Leader>b',
                '<cmd>ASToggle<cr>',
                icon = { icon = '', hl = 'DiagnosticInfo' },
                desc = 'Toggle autosave',
            },
        })

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
                    level = enabled and vim.log.levels.INFO or vim.log.levels.WARN,
                })
            end,
        })
        vim.api.nvim_create_autocmd('User', {
            pattern = 'AutoSaveWritePost',
            group = group,
            callback = function(args)
                if args.data.saved_buffer ~= nil then
                    local filename = vim.api.nvim_buf_get_name(args.data.saved_buffer)
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
                vim.api.nvim_exec_autocmds('User', { pattern = 'VisualEnter' })
            end,
        })
        vim.api.nvim_create_autocmd('ModeChanged', {
            group = visual_event_group,
            pattern = { '[vV\x16]*:*' },
            callback = function()
                vim.api.nvim_exec_autocmds('User', { pattern = 'VisualLeave' })
            end,
        })
    end,
}
