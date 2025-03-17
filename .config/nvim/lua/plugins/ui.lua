---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'rebelot/heirline.nvim',
        event = 'UIEnter',
        opts = function()
            local conditions = require 'heirline.conditions'
            local utils = require 'heirline.utils'
            local icons = require 'conf.icons'
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
                    local workspace = '~/'
                            .. vim.fs.relpath(
                                vim.env.HOME,
                                vim.g.workspace_root
                            )
                        or vim.g.workspace_root
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

            local FileNameBlock = {
                init = function(self)
                    self.filename = vim.api.nvim_buf_get_name(self.bufnr)
                end,
                hl = 'StatusLine',
            }

            local FileIcon = {
                init = function(self)
                    local extension = vim.fn.fnamemodify(self.filename, ':e')
                    self.icon, self.icon_color =
                        require('nvim-web-devicons').get_icon_color(
                            self.filename,
                            extension,
                            { default = true }
                        )
                end,
                condition = function(self)
                    return self.icon
                end,
                provider = function(self)
                    return string.format('%s ', self.icon)
                end,
                -- hl = function(self)
                --     return { fg = self.icon_color }
                -- end,
            }

            local function split(str, sep)
                local res = {}
                local n = 1
                for w in str:gmatch('([^' .. sep .. ']*)') do
                    res[n] = res[n] or w -- only set once (so the blank after a string is ignored)
                    if w == '' then
                        n = n + 1
                    end -- step forwards on a blank but not a string
                end
                return res
            end

            local function is_file(bufnr)
                return not conditions.buffer_matches({
                    buftype = { 'nofile', 'help', 'terminal' },
                }, bufnr)
            end

            local FilePath = {
                provider = function(self)
                    if not is_file(self.bufnr) then
                        return ''
                    end
                    local filename = self.filename
                    local fp = vim.fn.fnamemodify(filename, ':~:.')
                    if vim.fs.basename(filename) ~= '' then
                        -- not unnamed file
                        fp = vim.fs.dirname(fp)
                    end
                    local tbl = split(fp, '/')
                    local len = #tbl

                    -- TODO
                    -- if not conditions.width_percent_below(#filename, 0.25) then
                    --     filename = vim.fn.pathshorten(filename)
                    -- end
                    if len > 2 and not tbl[0] == '~' or len > 3 then
                        return '…/' .. table.concat(tbl, '/', len - 1) .. '/' -- shorten filepath to last 2 folders
                    -- alternative: only 1 containing folder using vim builtin function
                    -- return '…/' .. fn.fnamemodify(fn.expand '%', ':p:h:t') .. '/'
                    else
                        return fp .. '/'
                    end
                end,
            }

            local FileName = {
                provider = function(self)
                    local filename = vim.fs.basename(self.filename)

                    if filename == '' then
                        filename = '[unnamed]'
                    end

                    return filename
                end,
            }

            local FileFlags = {
                {
                    condition = function()
                        return vim.bo.modified
                    end,
                    provider = '',
                },
                {
                    condition = function()
                        return not vim.bo.modifiable or vim.bo.readonly
                    end,
                    provider = '',
                },
            }

            FileNameBlock = utils.insert(
                FileNameBlock,
                FileIcon,
                FilePath,
                FileName,
                Space,
                FileFlags,
                { provider = '%<' } -- this means that the statusline is cut here when there's not enough space
            )

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
                    return not vim.tbl_isempty(vim.diagnostic.count(self.bufnr))
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

            local Harpoon = {
                static = { icons = { mark = 'M' } },
                condition = function()
                    return package.loaded.harpoon
                end,
                provider = function(self)
                    local harpoon = require 'harpoon'
                    local list = harpoon:list()

                    local name = vim.fn.expand '%'
                    local item = list:get_by_value(name)

                    if not item then
                        return
                    end
                    return self.icons.mark
                end,
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
                update = {
                    'User',
                    pattern = 'DapProgressUpdate',
                    callback = vim.schedule_wrap(function()
                        vim.cmd.redrawstatus()
                    end),
                },
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
                    local status = neotest.state.status_counts(
                        self.adapter_ids[1],
                        { buffer = self.bufnr }
                    )
                    return status
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
                        return self.status.total > 0
                    end,
                    {
                        -- {
                        --     init = function(self)
                        --         self.adapter = vim.split(
                        --             vim.split(
                        --                 self.adapter_ids[1],
                        --                 ':',
                        --                 { plain = true }
                        --             )[1],
                        --             'neotest-',
                        --             { plain = true }
                        --         )[2]
                        --     end,
                        --     provider = function(self)
                        --         return string.format('%s ', self.adapter)
                        --     end,
                        -- },
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
            MacroRecordingBlock =
                utils.insert(MacroRecordingBlock, MacroRecording)

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
                        CANCELED = '',
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
                        self.filename = vim.api.nvim_buf_get_name(self.buf)
                    end,
                    provider = function(self)
                        if self.filename == '' then
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

            return {
                statusline = {
                    init = function(self)
                        self.bufnr = vim.api.nvim_get_current_buf()
                    end,
                    MacroRecordingBlock,
                    WorkDir,
                    Space,
                    Diagnostics,
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
    },
    {
        'Bekaboo/dropbar.nvim',
        event = 'FileType',
        ---@module 'dropbar.configs'
        ---@type dropbar_configs_t
        opts = {
            bar = {
                ---@type boolean|fun(buf: integer, win: integer, info: table?): boolean
                enable = function(buf, win, _)
                    if
                        not vim.api.nvim_buf_is_valid(buf)
                        or not vim.api.nvim_win_is_valid(win)
                        or vim.fn.win_gettype(win) ~= ''
                        or vim.bo[buf].buftype ~= ''
                        or vim.wo[win].winbar ~= ''
                        or vim.tbl_contains(
                            { 'gitcommit', 'gitrebase' },
                            vim.bo[buf].ft
                        )
                    then
                        return false
                    end

                    local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
                    if stat and stat.size > 1024 * 1024 then
                        return false
                    end

                    return vim.bo[buf].ft == 'markdown'
                        or pcall(vim.treesitter.get_parser, buf)
                        or not vim.tbl_isempty(vim.lsp.get_clients {
                            bufnr = buf,
                            method = 'textDocument/documentSymbol',
                        })
                end,
                ---@type dropbar_source_t[]|fun(buf: integer, win: integer): dropbar_source_t[]
                sources = function(buf, _)
                    local sources = require 'dropbar.sources'
                    if vim.bo[buf].ft == 'markdown' then
                        return {
                            sources.path,
                            sources.markdown,
                        }
                    end
                    if vim.bo[buf].buftype == 'terminal' then
                        return {
                            sources.terminal,
                        }
                    end

                    local clients = vim.lsp.get_clients {
                        bufnr = buf,
                        method = 'textDocument/documentSymbol',
                    }
                    if not vim.tbl_isempty(clients) then
                        return {
                            sources.path,
                            sources.lsp,
                        }
                    else
                        return {
                            sources.path,
                            sources.treesitter,
                        }
                    end
                end,
            },
            sources = {
                treesitter = {
                    valid_types = {
                        'array',
                        'boolean',
                        'break_statement',
                        'call',
                        'case_statement',
                        'class',
                        'constant',
                        'constructor',
                        'continue_statement',
                        'delete',
                        'do_statement',
                        'element',
                        'enum',
                        'enum_member',
                        'event',
                        'for_statement',
                        'function',
                        'h1_marker',
                        'h2_marker',
                        'h3_marker',
                        'h4_marker',
                        'h5_marker',
                        'h6_marker',
                        'if_statement',
                        'interface',
                        'keyword',
                        'macro',
                        'method',
                        -- 'module', -- remove for Python, otherwise yields a lot of spam, e.g. `from __future__ import annotations`
                        'namespace',
                        'null',
                        'number',
                        'operator',
                        'package',
                        'pair',
                        'property',
                        'reference',
                        'repeat',
                        'rule_set',
                        'scope',
                        'specifier',
                        'struct',
                        'switch_statement',
                        'type',
                        'type_parameter',
                        'unit',
                        'value',
                        'variable',
                        'while_statement',
                        'declaration',
                        'field',
                        'identifier',
                        'object',
                        'statement',
                    },
                },
                lsp = {
                    valid_symbols = {
                        'File',
                        -- 'Module',
                        -- 'Namespace',
                        -- 'Package',
                        'Class',
                        'Method',
                        'Constructor',
                        'Interface',
                        'Function',
                    },
                },
            },
            icons = {
                kinds = {
                    symbols = {
                        Array = '󰅪 ',
                        Boolean = '◩ ',
                        BreakStatement = '󰙧 ',
                        Call = '󰃷 ',
                        CaseStatement = '󱃙 ',
                        Class = '󰙅 ',
                        Color = '󰏘 ',
                        Constant = '󰏿 ',
                        Constructor = ' ',
                        ContinueStatement = '→ ',
                        Copilot = ' ',
                        Declaration = '󰙠 ',
                        Delete = '󰩺 ',
                        DoStatement = '󰑖 ',
                        Enum = ' ',
                        EnumMember = ' ',
                        Event = ' ',
                        Field = ' ',
                        File = '󰈙 ',
                        Folder = '󰉋 ',
                        ForStatement = '󰑖 ',
                        Function = '󰊕 ',
                        H1Marker = '󰉫 ', -- Used by markdown treesitter parser
                        H2Marker = '󰉬 ',
                        H3Marker = '󰉭 ',
                        H4Marker = '󰉮 ',
                        H5Marker = '󰉯 ',
                        H6Marker = '󰉰 ',
                        Identifier = '󰀫 ',
                        IfStatement = '󰇉 ',
                        Interface = '󰕘 ',
                        Keyword = '󰌋 ',
                        List = '󰅪 ',
                        Log = '󰦪 ',
                        Lsp = ' ',
                        Macro = '󰁌 ',
                        MarkdownH1 = '󰉫 ', -- Used by builtin markdown source
                        MarkdownH2 = '󰉬 ',
                        MarkdownH3 = '󰉭 ',
                        MarkdownH4 = '󰉮 ',
                        MarkdownH5 = '󰉯 ',
                        MarkdownH6 = '󰉰 ',
                        Method = ' ',
                        Module = ' ',
                        Namespace = '󰌗 ',
                        Null = '󰢤 ',
                        Number = '󰎠 ',
                        Object = ' ',
                        Operator = '󰆕 ',
                        Package = '󰆦 ',
                        Pair = ' ',
                        Property = ' ',
                        Reference = '󰋺 ',
                        Regex = ' ',
                        Repeat = '󰑖 ',
                        Scope = ' ', -- FIXME: 󰅩 symbol rendered incorrectly in Ghostty
                        Snippet = '󱡄 ',
                        Specifier = '󰦪 ',
                        Statement = ' ',
                        String = '󰉾 ',
                        Struct = '󱡠 ',
                        SwitchStatement = '󰺟 ',
                        Terminal = ' ',
                        Text = ' ',
                        Type = ' ',
                        TypeParameter = '󰊄 ',
                        Unit = ' ',
                        Value = ' ',
                        Variable = '󰀫 ',
                        WhileStatement = '󰑖 ',
                    },
                },
            },
        },
        config = function(_, opts)
            require('dropbar').setup(opts)
            require('which-key').add {
                {
                    '<Leader>;',
                    function()
                        require('dropbar.api').pick()
                    end,
                    desc = 'Winbar pick symbol',
                    icon = '󱐀',
                },
            }

            vim.api.nvim_create_autocmd('LspAttach', {
                desc = 'Register LSP source and disable Treesitter source when an LS that supports documentSymbol attaches.',
                group = vim.api.nvim_create_augroup(
                    'DropBarLspAttachRefreshSources',
                    { clear = true }
                ),
                callback = function(args)
                    local bufnr = args.buf
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if
                        client
                        and client:supports_method 'textDocument/documentSymbol'
                    then
                        local sources = require 'dropbar.sources'
                        local utils = require 'dropbar.utils'
                        for win in pairs(_G.dropbar.bars[bufnr]) do
                            _G.dropbar.bars[bufnr][win].sources = {
                                sources.path,
                                sources.lsp,
                            }
                            utils.bar.exec('update', { win = win })
                        end
                    end
                end,
            })
        end,
    },
    { 'kyazdani42/nvim-web-devicons', lazy = true },
    { 'MunifTanjim/nui.nvim', lazy = true },
    {
        'grapp-dev/nui-components.nvim',
        dependencies = { 'MunifTanjim/nui.nvim' },
        lazy = true,
    },
    {
        'folke/noice.nvim',
        event = 'VeryLazy',
        keys = {
            {
                '<M-Enter>', -- Alt-Enter
                function()
                    require('noice').redirect 'Inspect'
                end,
                desc = 'Show inspect in popup',
            },
        },
        opts = {
            cmdline = {
                format = {
                    cmdline = { pattern = '^:', icon = ':' },
                },
            },
            lsp = {
                signature = { enabled = false },
                hover = { enabled = true, silent = true },
            },
            routes = {
                {
                    filter = {
                        event = 'cmdline',
                        find = '^%s*[/?]',
                    },
                    view = 'cmdline',
                },
            },
            presets = {
                long_message_to_split = false, -- long messages will be sent to a split
                lsp_doc_border = true, -- add a border to hover docs and signature help
            },
        },
    },
    {
        'folke/zen-mode.nvim',
        cmd = 'ZenMode',
        dependencies = {
            {
                'folke/twilight.nvim',
                cmd = 'Twilight',
                opts = { context = 10 },
            },
        },
        opts = {
            window = {
                options = {
                    -- signcolumn = 'no', -- disable signcolumn
                    list = false, -- disable whitespace characters
                },
            },
            plugins = {
                options = {
                    enabled = true,
                    laststatus = 0, -- turn off the statusline in zen mode
                },
                tmux = { enabled = true },
                kitty = {
                    enabled = true,
                    font = '+4',
                },
            },
        },
    },
}
