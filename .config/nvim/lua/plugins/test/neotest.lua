local icons = require('conf.icons')

---@type LazeSpec
return {
    'nvim-neotest/neotest',
    main = 'neotest',
    module = 'neotest',
    dependencies = { 'nvim-neotest/nvim-nio', 'stevearc/overseer.nvim' },
    init = function()
        require('which-key').add({
            { '<Leader>t', group = 'Test', icon = '' },
        })
    end,
    keys = {
        {
            '<Leader>tf',
            function()
                require('neotest').run.run({ suite = false })
            end,
            desc = 'Nearest function',
        },
        {
            '<Leader>tb',
            function()
                require('neotest').run.run({
                    vim.api.nvim_buf_get_name(0),
                    suite = false,
                })
            end,
            desc = 'Entire file/buffer',
        },
        {
            '<Leader>ta',
            function()
                for _, adapter_id in ipairs(require('neotest').state.adapter_ids()) do
                    require('neotest').run.run({
                        suite = true,
                        adapter_id = adapter_id,
                    })
                end
            end,
            desc = 'Entire project',
        },
        {
            '<Leader>td',
            function()
                require('conf.dap.adapters').load(vim.bo.filetype)
                require('neotest').run.run({
                    strategy = 'dap',
                    suite = false,
                })
            end,
            desc = 'Debug nearest function',
        },
        {
            '<Leader>tl',
            function()
                require('neotest').run.run_last()
            end,
            desc = 'Re-run last',
        },
        {
            '<Leader>ts',
            function()
                if vim.bo.filetype == 'neotest-summary' then
                    require('neotest').summary.close()
                    return
                end

                local target = require('conf.workspace').find_or_create_tab('tests')
                if vim.api.nvim_get_current_tabpage() ~= target then
                    vim.api.nvim_set_current_tabpage(target)
                end

                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(target)) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    if vim.bo[buf].filetype == 'neotest-summary' then
                        vim.api.nvim_set_current_win(win)
                        return
                    end
                end

                require('neotest').summary.open()
            end,
            desc = 'Toggle summary',
        },
        {
            '<Leader>tm',
            function()
                if vim.tbl_isempty(require('neotest').summary.marked()) then
                    require('neotest.lib').notify(
                        'No marked tests',
                        vim.log.levels.WARN
                    )
                    return
                end
                require('neotest').summary.run_marked()
            end,
            desc = 'Marked',
        },
        {
            '<Leader>tq',
            function()
                require('neotest').run.stop()
            end,
            desc = 'Abort test run',
        },
        {
            ']t',
            function()
                require('neotest').jump.next({ status = 'failed' })
            end,
            desc = 'Next failed test',
        },
        {
            '[t',
            function()
                require('neotest').jump.prev({ status = 'failed' })
            end,
            desc = 'Prev failed test',
        },
    },
    config = function()
        ---@module 'neotest.config'
        ---@type neotest.Config
        local opts = {
            ---@diagnostic disable-next-line: missing-fields
            floating = { border = 'single' },
            adapters = {},
            consumers = {
                notify = function(client)
                    client.listeners.results = function(_, results, partial)
                        if partial then
                            return
                        end
                        local error = vim.iter(vim.tbl_values(results))
                            :any(function(result)
                                return not (
                                    result.errors == nil
                                    or vim.tbl_isempty(result.errors)
                                )
                            end)
                        require('neotest.lib').notify(
                            'Tests completed',
                            error and vim.log.levels.WARN or vim.log.levels.INFO
                        )
                    end
                    return {}
                end,
                autocmd_run = function(client)
                    client.listeners.run = function()
                        vim.schedule(function()
                            vim.api.nvim_exec_autocmds('User', {
                                pattern = 'NeotestRun',
                                modeline = false,
                            })
                        end)
                    end
                    return {}
                end,
                autocmd_results = function(client)
                    client.listeners.results = function(adapter_id, results, partial)
                        vim.schedule(function()
                            vim.api.nvim_exec_autocmds('User', {
                                pattern = 'NeotestResult',
                                modeline = false,
                                data = {
                                    adapter_id = adapter_id,
                                    results = results,
                                    partial = partial,
                                },
                            })
                        end)
                    end
                    return {}
                end,
            },
            quickfix = {
                enabled = false,
                open = true,
            },
            output = {
                enabled = false, -- disabled in favor of overseer (live logs)
            },
            summary = {
                mappings = {
                    expand = { '<right>', '<left>', '<2-LeftMouse>' },
                    expand_all = 'e',
                    jumpto = '<CR>',
                },
            },
            icons = vim.tbl_extend('force', icons.test, {
                running_animated = {
                    '⠋',
                    '⠙',
                    '⠹',
                    '⠸',
                    '⠼',
                    '⠴',
                    '⠦',
                    '⠧',
                    '⠇',
                    '⠏',
                },
            }),
        }
        opts = vim.tbl_deep_extend('force', opts, {
            consumers = {
                overseer = require('neotest.consumers.overseer'),
            },
            strategies = {
                overseer = {
                    components = {
                        'default_neotest',
                    },
                    strategy = { 'jobstart_no_footer', use_terminal = true },
                },
            },
        }) --[[@as neotest.Config]]
        require('neotest').setup(opts)

        -- lazy-load adapters
        require('conf.neotest.adapters').load_project()

        vim.api.nvim_create_autocmd('FileType', {
            group = vim.api.nvim_create_augroup(
                'NeotestAdapterOnDemand',
                { clear = true }
            ),
            callback = function(args)
                require('conf.neotest.adapters').load(vim.bo[args.buf].filetype)
            end,
        })

        local function expand_summary_dirs_only()
            local neotest = require('neotest')
            local expanded = {}

            for _, adapter_id in ipairs(neotest.state.adapter_ids() or {}) do
                local tree = neotest.state.positions(adapter_id)
                if tree then
                    for _, pos in tree:iter() do
                        if pos.type == 'dir' then
                            expanded[pos.id] = true
                        end
                    end
                end
            end

            if next(expanded) then
                neotest.summary.render(expanded)
                return true
            end
            return false
        end

        vim.api.nvim_create_autocmd('User', {
            pattern = 'NeotestSummaryOpen',
            callback = function()
                -- discovery can still be running; retry briefly
                local tries = 0
                local timer = vim.uv.new_timer()
                timer:start(
                    0,
                    100,
                    vim.schedule_wrap(function()
                        if vim.uv.is_closing(timer) then
                            return
                        end

                        tries = tries + 1
                        if expand_summary_dirs_only() or tries > 20 then
                            timer:stop()
                            timer:close()
                        end
                    end)
                )
            end,
        })

        local augroup =
            vim.api.nvim_create_augroup('NeotestSummaryCursor', { clear = true })
        vim.api.nvim_create_autocmd('FileType', {
            group = augroup,
            pattern = 'neotest-summary',
            callback = function(args)
                vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
                    buffer = args.buf,
                    callback = require('conf.ui').cursor.hide,
                })
                vim.api.nvim_create_autocmd({ 'BufLeave', 'WinLeave' }, {
                    buffer = args.buf,
                    callback = require('conf.ui').cursor.show,
                })
                vim.schedule(function()
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if vim.api.nvim_win_get_buf(win) == args.buf then
                            vim.api.nvim_create_autocmd('CmdlineLeave', {
                                buffer = args.buf,
                                callback = function()
                                    if vim.api.nvim_get_current_win() == win then
                                        require('conf.ui').cursor.hide()
                                    end
                                end,
                                desc = 'Re-hide cursor when leaving cmdline back to window',
                            })
                            return
                        end
                    end
                end)
            end,
        })
    end,
}
