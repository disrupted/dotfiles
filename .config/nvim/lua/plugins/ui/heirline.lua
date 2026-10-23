local icons = require 'conf.icons'

---@type LazeSpec
return {
    'rebelot/heirline.nvim',
    main = 'heirline',
    module = 'heirline',
    event = 'UIEnter',
    config = function()
        local conditions = require 'heirline.conditions'
        local utils = require 'heirline.utils'
        local lazy_require = require('utils').lazy_require

        vim.api.nvim_create_autocmd('ColorScheme', {
            group = vim.api.nvim_create_augroup('Heirline', {}),
            callback = function()
                utils.on_colorscheme {}
            end,
            desc = 'Reload highlights on colorscheme or background change',
        })

        local Align = { provider = '%=' }
        local Space = { provider = ' ' }

        local WorkDir = {
            static = { icon = '' },
            provider = function(self)
                local workspace = vim.g.workspace_root
                local relpath =
                    vim.fs.relpath(vim.env.HOME, vim.g.workspace_root)
                if relpath then
                    workspace = relpath == '.' and '~' or '~/' .. relpath
                end
                -- if not conditions.width_percent_below(#workspace, 0.25) then
                --     workspace = vim.fn.pathshorten(workspace)
                -- end
                return string.format(' %s %s', self.icon, workspace)
            end,
            update = { 'DirChanged' },
            hl = function()
                local hl = utils.get_highlight 'StatusLine'
                return { fg = hl.fg, bg = hl.bg, bold = true }
            end,
        }

        local function is_file(bufnr)
            return not conditions.buffer_matches({
                buftype = { 'nofile', 'help', 'terminal' },
            }, bufnr)
        end

        local GitStatus = {
            condition = function(self)
                return vim.b[self.bufnr].gitsigns_status_dict
                    and is_file(self.bufnr)
            end,
            static = {
                icons = {
                    added = '+',
                    changed = '~',
                    removed = '-',
                },
            },
            init = function(self)
                self.status = vim.b[self.bufnr].gitsigns_status_dict
                self.status.added = self.status.added or 0
                self.status.changed = self.status.changed or 0
                self.status.removed = self.status.removed or 0
                self.has_changes = self.status.added ~= 0
                    or self.status.removed ~= 0
                    or self.status.changed ~= 0
            end,

            {
                condition = function(self)
                    return self.status.added ~= 0
                end,
                provider = function(self)
                    return string.format(
                        '%s%s ',
                        self.icons.added,
                        self.status.added
                    )
                end,
                hl = 'GitSignsAdd',
            },
            {
                condition = function(self)
                    return self.status.changed ~= 0
                end,
                provider = function(self)
                    return string.format(
                        '%s%s ',
                        self.icons.changed,
                        self.status.changed
                    )
                end,
                hl = 'GitSignsChange',
            },
            {
                condition = function(self)
                    return self.status.removed ~= 0
                end,
                provider = function(self)
                    return string.format(
                        '%s%s ',
                        self.icons.removed,
                        self.status.removed
                    )
                end,
                hl = 'GitSignsDelete',
            },
        }

        local GhPR = {
            condition = function()
                return vim.g.git_pr and vim.g.git_pr.state == 'OPEN'
            end,
            provider = icons.git.pull_request .. ' ',
        }
        local GhPRTitle = {
            condition = function()
                return GhPR.condition() and #vim.g.git_pr.title <= 50
            end,
            provider = function()
                return vim.g.git_pr.title
            end,
        }
        table.insert(GhPR, GhPRTitle)

        local GitBranch = {
            update = {
                'User',
                pattern = 'GitRefresh',
                callback = vim.schedule_wrap(function()
                    vim.cmd.redrawstatus()
                end),
            },

            GhPR,
            {
                condition = function()
                    return (vim.g.git_branch or vim.g.git_head)
                        and not GhPRTitle.condition()
                end,
                provider = function()
                    return string.format(
                        '%s %s',
                        vim.g.git_branch and icons.git.branch
                            or icons.git.commit,
                        vim.g.git_branch or vim.g.git_head
                    )
                end,
            },
        }

        local Diagnostics = {
            condition = function(self)
                return vim.diagnostic.is_enabled { bufnr = self.bufnr }
                    and not vim.tbl_isempty(vim.diagnostic.count(self.bufnr))
            end,
            init = function(self)
                self.status = vim.diagnostic.count(self.bufnr)
            end,
            update = {
                'DiagnosticChanged',
                'BufWinEnter',
                callback = vim.schedule_wrap(function()
                    vim.cmd.redrawstatus()
                end),
            },

            {
                static = {
                    severity = vim.diagnostic.severity.ERROR,
                    icon = '',
                },
                condition = function(self)
                    local count = self.status[self.severity]
                    return count and count > 0
                end,
                provider = function(self)
                    return string.format(
                        '%s %s ',
                        self.icon,
                        self.status[self.severity]
                    )
                end,
                hl = 'DiagnosticSignError',
            },
            {
                static = {
                    severity = vim.diagnostic.severity.WARN,
                    icon = '',
                },
                condition = function(self)
                    local count = self.status[self.severity]
                    return count and count > 0
                end,
                provider = function(self)
                    return string.format(
                        '%s %s ',
                        self.icon,
                        self.status[self.severity]
                    )
                end,
                hl = 'DiagnosticSignWarn',
            },
            {
                static = {
                    severity = vim.diagnostic.severity.INFO,
                    icon = '',
                },
                condition = function(self)
                    local count = self.status[self.severity]
                    return count and count > 0
                end,
                provider = function(self)
                    return string.format(
                        '%s %s ',
                        self.icon,
                        self.status[self.severity]
                    )
                end,
                hl = 'DiagnosticSignInfo',
            },
        }

        local dap = lazy_require 'dap'
        local DAPStatus = {
            condition = function()
                return package.loaded.dap and dap.session() ~= nil
            end,
            static = { icon = icons.misc.bug },
            provider = function(self)
                return self.icon .. ' '
            end,
            -- FIXME: doesn't update file buffer
            -- update = {
            --     'User',
            --     pattern = 'DapProgressUpdate',
            --     callback = vim.schedule_wrap(function()
            --         vim.cmd.redrawstatus()
            --     end),
            -- },
            hl = 'DiagnosticError',
            {
                provider = function()
                    return dap.status() .. ' '
                end,
                hl = 'StatusLine',
            },
        }

        local neotest = lazy_require 'neotest'
        local NeoTestBlock = {
            condition = function()
                return package.loaded.neotest
                    and conditions.is_active()
                    and #neotest.state.adapter_ids() > 0
            end,
            init = function(self)
                self.adapter_ids = neotest.state.adapter_ids()
            end,
        }
        local NeoTest = {
            condition = function(self)
                return neotest.state.status_counts(
                    self.adapter_ids[1],
                    { buffer = self.bufnr }
                )
            end,
            init = function(self)
                self.status = neotest.state.status_counts(
                    self.adapter_ids[1],
                    { buffer = self.bufnr }
                )
            end,
            static = {
                icon = {
                    total = icons.test.notify,
                    passed = icons.test.passed,
                    failed = icons.test.failed,
                    skipped = icons.test.skipped,
                    running = icons.test.running,
                },
            },
            update = {
                'User',
                pattern = { 'NeotestRun', 'NeotestResult' },
                callback = vim.schedule_wrap(function()
                    vim.cmd.redrawstatus()
                end),
            },
            {
                condition = function(self)
                    return self.status.total > 0 or self.status.running > 0
                end,
                {
                    {
                        provider = function(self)
                            return string.format(
                                '%s %s ',
                                self.icon.total,
                                self.status.total
                            )
                        end,
                        hl = 'StatusLineNC',
                    },
                    {
                        condition = function(self)
                            return self.status.running > 0
                        end,
                        provider = function(self)
                            return string.format(
                                '%s %s ',
                                self.icon.running,
                                self.status.running
                            )
                        end,
                        hl = 'NeotestRunning',
                    },
                    {
                        condition = function(self)
                            return self.status.passed > 0
                        end,
                        provider = function(self)
                            return string.format(
                                '%s %s ',
                                self.icon.passed,
                                self.status.passed
                            )
                        end,
                        hl = 'NeotestPassed',
                    },
                    {
                        condition = function(self)
                            return self.status.failed > 0
                        end,
                        provider = function(self)
                            return string.format(
                                '%s %s ',
                                self.icon.failed,
                                self.status.failed
                            )
                        end,
                        hl = 'NeotestFailed',
                    },
                    {
                        condition = function(self)
                            return self.status.skipped > 0
                        end,
                        provider = function(self)
                            return string.format(
                                '%s %s ',
                                self.icon.skipped,
                                self.status.skipped
                            )
                        end,
                        hl = 'NeotestSkipped',
                    },
                },
                Space,
            },
        }
        NeoTestBlock = utils.insert(NeoTestBlock, NeoTest, Space)

        local MacroRecordingBlock = {
            condition = conditions.is_active,
            init = function(self)
                self.register = vim.fn.reg_recording()
            end,
        }
        local MacroRecording = {
            condition = function(self)
                return self.register ~= ''
            end,
            static = { icon = '' },
            {
                provider = function(self)
                    return string.format(' %s ', self.icon)
                end,
                hl = 'DiagnosticSignError',
            },
            {
                provider = function(self)
                    return string.format('%s ', self.register)
                end,
                hl = { bold = true },
            },
            hl = function()
                return { bg = utils.get_highlight('SpecialKey').fg }
            end,
            update = { 'RecordingEnter', 'RecordingLeave' },
        }
        MacroRecordingBlock = utils.insert(MacroRecordingBlock, MacroRecording)

        local function OverseerTasksForStatus(status)
            return {
                condition = function(self)
                    return self.tasks[status]
                end,
                provider = function(self)
                    return string.format(
                        '%s %d ',
                        self.icon[status],
                        #self.tasks[status]
                    )
                end,
                hl = function()
                    return string.format('Overseer%s', status)
                end,
            }
        end

        local Overseer = {
            condition = function()
                return package.loaded.overseer
            end,
            init = function(self)
                local tasks = require('overseer.task_list').list_tasks {
                    unique = true,
                }
                local tasks_by_status =
                    require('overseer.util').tbl_group_by(tasks, 'status')
                self.tasks = tasks_by_status
            end,
            static = {
                icon = {
                    CANCELED = '',
                    FAILURE = '󰅚',
                    SUCCESS = '󰄴',
                    RUNNING = '󰑮',
                },
            },
            OverseerTasksForStatus 'CANCELED',
            OverseerTasksForStatus 'RUNNING',
            OverseerTasksForStatus 'SUCCESS',
            OverseerTasksForStatus 'FAILURE',
        }

        vim.api.nvim_create_user_command('TabName', function(opts)
            vim.api.nvim_tabpage_set_var(0, 'tabname', opts.args)
            vim.cmd.redrawtabline()
        end, {
            nargs = 1,
            desc = 'Assign custom name for current tabpage',
        })

        local Tab = {
            init = function(self)
                local win = vim.api.nvim_tabpage_get_win(self.tabpage)
                self.buf = vim.api.nvim_win_get_buf(win)
            end,
            hl = function(self)
                if self.is_active then
                    return 'TabLineSel'
                else
                    return 'TabLine'
                end
            end,
            Space,
            {
                provider = function(self)
                    return self.tabnr
                end,
            },
            Space,
            {
                init = function(self)
                    local success, tabname = pcall(
                        vim.api.nvim_tabpage_get_var,
                        self.tabpage,
                        'tabname'
                    )
                    self.tabname = success and tabname or nil
                    self.filename = vim.api.nvim_buf_get_name(self.buf)
                end,
                provider = function(self)
                    if self.tabname then
                        return self.tabname
                    elseif self.filename == '' then
                        return '[No Name]'
                    else
                        local name = vim.fs.basename(self.filename)
                        if #name > 16 then
                            name = name:sub(1, 15) .. '…'
                        end
                        return name
                    end
                end,
            },
        }

        local LSPActive = {
            condition = conditions.lsp_attached,
            update = {
                'LspAttach',
                'LspDetach',
                'BufWinEnter',
            },
            hl = function()
                local hl = utils.get_highlight 'StatusLineNC'
                return { fg = hl.fg, bg = hl.bg, bold = true }
            end,
            {
                provider = function()
                    return vim.iter(vim.lsp.get_clients { bufnr = 0 })
                        :map(function(server)
                            return server.name
                        end)
                        :join ' '
                end,
            },
            Space,
        }

        require('heirline').setup {
            statusline = {
                init = function(self)
                    self.bufnr = vim.api.nvim_get_current_buf()
                end,
                MacroRecordingBlock,
                WorkDir,
                Space,
                Diagnostics,
                LSPActive,
                Align,
                Align,
                DAPStatus,
                Overseer,
                NeoTestBlock,
                GitStatus,
                GitBranch,
            },
            tabline = {
                condition = function()
                    return #vim.api.nvim_list_tabpages() > 1
                end,
                utils.make_tablist(Tab),
                { hl = 'TabLineFill' },
            },
            opts = {
                disable_winbar_cb = function(args)
                    return conditions.buffer_matches({
                        buftype = { 'nofile', 'prompt', 'help', 'quickfix' },
                        filetype = {
                            '^qf$',
                            '^help$',
                            '^git.*',
                            'Outline',
                            'Trouble',
                            'NvimTree',
                            'dap-repl',
                            '^dapui',
                            'harpoon',
                        },
                    }, args.buf)
                end,
            },
        }
    end,
}
