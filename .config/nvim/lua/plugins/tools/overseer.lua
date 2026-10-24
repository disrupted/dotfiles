---@type LazeSpec
return {
    'stevearc/overseer.nvim',
    main = 'overseer',
    module = 'overseer',
    cmd = {
        'OverseerOpen',
        'OverseerToggle',
        'OverseerRun',
        'OverseerShell',
    },
    keys = {
        { '<Bslash>', '<cmd>OverseerToggle<cr>', desc = 'Toggle Overseer' },
        { '<M-Bslash>', '<cmd>OverseerRun<cr>', desc = 'Overseer run' },
    },
    config = function()
        ---@type overseer.SetupOpts
        local opts = {
            form = {
                border = 'rounded',
            },
            task_win = {
                border = 'rounded',
                padding = 10,
            },
            task_list = {
                keymaps = {
                    ['<C-j>'] = false,
                    ['<C-k>'] = false,
                    ['<C-h>'] = false,
                    ['<C-l>'] = false,
                    ['<C-u>'] = 'keymap.scroll_output_up',
                    ['<C-d>'] = 'keymap.scroll_output_down',
                    [']]'] = 'keymap.next_task',
                    ['[['] = 'keymap.prev_task',
                    ['j'] = 'keymap.next_task',
                    ['k'] = 'keymap.prev_task',
                    ['l'] = '<CMD>wincmd l<CR>',
                },
                direction = 'bottom',
                min_height = 25,
                max_height = 25,
            },
            component_aliases = {
                default_neotest = {
                    {
                        'open_output',
                        direction = 'dock',
                        focus = false,
                        -- on_start = 'never',
                        -- on_complete = 'failure',
                    },
                    'on_exit_set_status',
                    'on_complete_dispose',
                },
            },
        }
        local overseer = require('overseer')
        local STATUS = require('overseer.constants').STATUS
        overseer.setup(opts)

        -- Monkey-patch the JobstartStrategy to use a fixed width
        local JobstartStrategy = require('overseer.strategy.jobstart')
        local original_start = JobstartStrategy.start
        ---@diagnostic disable-next-line: duplicate-set-field, redundant-parameter
        JobstartStrategy.start = function(self, task)
            -- Temporarily override vim.o.columns during jobstart
            local saved_columns = vim.o.columns
            vim.o.columns = saved_columns - 40 + 3
            ---@diagnostic disable-next-line: redundant-parameter, param-type-mismatch
            local result = original_start(self, task)
            vim.o.columns = saved_columns
            return result
        end

        vim.api.nvim_create_autocmd('FileType', {
            pattern = 'OverseerOutput',
            callback = function(args)
                -- scheduling is necessary because on FileType event the buffer is not assigned to a window yet
                vim.schedule(function()
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if vim.api.nvim_win_get_buf(win) == args.buf then
                            vim.wo[win].fillchars = 'eob: '
                            return
                        end
                    end
                end)
            end,
        })

        local augroup =
            vim.api.nvim_create_augroup('OverseerListCursor', { clear = true })
        vim.api.nvim_create_autocmd('FileType', {
            group = augroup,
            pattern = 'OverseerList',
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

        local function _toggle_runner(window)
            if vim.bo.buftype == 'terminal' then
                vim.cmd('close')
                return
            end

            -- check for Overseer window
            local task_list = require('overseer.task_list')
            local tasks = overseer.list_tasks({
                status = {
                    STATUS.RUNNING,
                    STATUS.SUCCESS,
                    STATUS.FAILURE,
                    STATUS.CANCELED,
                },
                sort = task_list.sort_finished_recently,
            })

            if vim.tbl_isempty(tasks) then
                Snacks.notify.warn('No tasks found', { title = 'Overseer' })
            else
                local most_recent = tasks[1]
                if not most_recent then
                    return
                end
                overseer.run_action(most_recent, 'open ' .. window)
            end
        end

        -- vim.keymap.set('n', '|', function()
        --     toggle_runner 'float'
        -- end, { desc = 'Overseer: open task in floating window' })
    end,
}
