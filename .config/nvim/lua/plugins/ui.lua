return {
    {
        'rcarriga/nvim-notify',
        lazy = true,
        opts = {
            stages = 'static',
            render = 'minimal',
            minimum_width = 10,
            -- timeout = 5000,
        },
        config = function(_, opts)
            local notify = require 'notify'
            notify.setup(opts)
            vim.notify = notify
        end,
    },
    {
        'rebelot/heirline.nvim',
        event = 'UIEnter',
        dependencies = { 'Zeioth/heirline-components.nvim' },
        opts = function()
            local heirline = require 'heirline'
            local lib = require 'heirline-components.all'
            lib.init.subscribe_to_events()
            local conditions = require 'heirline.conditions'
            local utils = require 'heirline.utils'

            local colors = require('one.colors').get()
            heirline.load_colors(colors)
            local lazy_require = require('utils').lazy_require

            local augroup =
                vim.api.nvim_create_augroup('Heirline', { clear = true })
            vim.api.nvim_create_autocmd('ColorScheme', {
                callback = function()
                    utils.on_colorscheme(require('one.colors').get())
                end,
                group = augroup,
            })

            local Align = { provider = '%=' }
            local Space = { provider = ' ' }

            local WorkDir = {
                static = { icon = '' },
                init = function(self)
                    self.cwd = assert(vim.uv.cwd())
                end,
                provider = function(self)
                    local cwd = vim.fn.fnamemodify(self.cwd, ':~')
                    -- if not conditions.width_percent_below(#cwd, 0.25) then
                    --     cwd = vim.fn.pathshorten(cwd)
                    -- end
                    return string.format(' %s %s', self.icon, cwd)
                end,
                update = { 'DirChanged' },
                hl = {
                    fg = 'mono_1',
                    bg = 'syntax_cursor',
                    bold = true,
                },
            }

            local FileNameBlock = {
                init = function(self)
                    self.filename = vim.api.nvim_buf_get_name(self.bufnr)
                end,
                hl = { bold = false },
            }

            local FileIcon = {
                init = function(self)
                    local filename = self.filename
                    local extension = vim.fn.fnamemodify(filename, ':e')
                    self.icon, self.icon_color =
                        require('nvim-web-devicons').get_icon_color(
                            filename,
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
                local bt =
                    vim.api.nvim_get_option_value('buftype', { buf = bufnr })
                return bt ~= 'nofile' and bt ~= 'terminal'
            end

            local FilePath = {
                provider = function(self)
                    if not is_file(self.bufnr) then
                        return ''
                    end
                    local filename = self.filename
                    local fp = vim.fn.fnamemodify(filename, ':~:.')
                    if vim.fn.fnamemodify(filename, ':t') ~= '' then
                        -- not unnamed file
                        fp = vim.fn.fnamemodify(fp, ':h')
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
                    local filename = vim.fn.fnamemodify(self.filename, ':t')

                    if filename == '' then
                        filename = '[unnamed]'
                    end

                    return filename
                end,
                -- hl = { fg = utils.get_highlight('Directory').fg },
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

            local Git = {
                condition = conditions.is_git_repo,

                hl = { bg = 'syntax_cursor' },
                static = {
                    icons = {
                        added = '+',
                        changed = '~',
                        removed = '-',
                        head = '',
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
                            '%s%s',
                            self.icons.added,
                            self.status.added
                        )
                    end,
                    hl = {
                        fg = 'hue_4',
                        bg = 'syntax_cursor',
                    },
                },
                Space,
                {
                    condition = function(self)
                        return self.status.changed ~= 0
                    end,
                    provider = function(self)
                        return string.format(
                            '%s%s',
                            self.icons.changed,
                            self.status.changed
                        )
                    end,
                    hl = {
                        fg = 'hue_6_2',
                        bg = 'syntax_cursor',
                    },
                },
                Space,
                {
                    condition = function(self)
                        return self.status.removed ~= 0
                    end,
                    provider = function(self)
                        return string.format(
                            '%s%s',
                            self.icons.removed,
                            self.status.removed
                        )
                    end,
                    hl = {
                        fg = 'hue_5',
                        bg = 'syntax_cursor',
                    },
                },
                Space,
                { -- git branch name
                    provider = function(self)
                        return string.format(
                            '%s %s',
                            self.icons.head,
                            self.status.head
                        )
                    end,
                    hl = { bold = false },
                },
            }

            local Diagnostics = {

                condition = function(self)
                    return not vim.tbl_isempty(vim.diagnostic.count(self.bufnr))
                end,

                hl = { bg = 'syntax_cursor' },

                init = function(self)
                    self.status = vim.diagnostic.count(self.bufnr)
                end,

                update = { 'DiagnosticChanged', 'BufEnter' },

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
                    hl = {
                        fg = 'hue_5',
                        bg = 'syntax_cursor',
                    },
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
                    hl = {
                        fg = 'hue_6_2',
                        bg = 'syntax_cursor',
                    },
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
                    hl = {
                        fg = 'hue_2',
                        bg = 'syntax_cursor',
                    },
                },
            }

            local Harpoon = {
                static = { icons = { mark = 'M' } },
                condition = function()
                    return package.loaded['harpoon']
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
            local DAPMessages = {
                static = { icon = '' },
                condition = function()
                    return package.loaded['dap'] and dap.session() ~= nil
                end,
                init = function(self)
                    self.status = dap.status()
                end,
                provider = function(self)
                    return string.format('%s %s', self.icon, self.status)
                end,
            }

            local neotest = lazy_require 'neotest'
            local NeoTestBlock = {
                condition = function()
                    return package.loaded['neotest']
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
                        total = '',
                        passed = '',
                        failed = '',
                        skipped = '',
                        running = '',
                    },
                },
                {
                    condition = function(self)
                        return self.status.total > 0
                    end,
                    init = function(self)
                        self.adapter = vim.split(
                            vim.split(
                                self.adapter_ids[1],
                                ':',
                                { plain = true }
                            )[1],
                            'neotest-',
                            { plain = true }
                        )[2]
                    end,
                    provider = function(self)
                        -- return string.format('%s ', self.adapter)
                    end,
                    hl = { bg = 'syntax_cursor' },
                    {
                        {
                            condition = function(self)
                                return self.status.total > 0
                            end,
                            provider = function(self)
                                return string.format(
                                    '%s %s ',
                                    self.icon.total,
                                    self.status.total
                                )
                            end,
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
                            hl = function()
                                local hl = utils.get_highlight 'NeotestRunning'
                                return hl
                            end,
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
                            hl = function()
                                local hl = utils.get_highlight 'NeotestPassed'
                                return hl
                            end,
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
                            hl = function()
                                local hl = utils.get_highlight 'NeotestFailed'
                                return hl
                            end,
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
                            hl = function()
                                local hl = utils.get_highlight 'NeotestSkipped'
                                return hl
                            end,
                        },
                    },
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
                    hl = { fg = colors.hue_5 },
                },
                {
                    provider = function(self)
                        return string.format('%s ', self.register)
                    end,
                    hl = { bold = true },
                },
                hl = { bg = colors.yellow },
                update = { 'RecordingEnter', 'RecordingLeave' },
            }
            MacroRecordingBlock =
                utils.insert(MacroRecordingBlock, MacroRecording)

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
                    DAPMessages,
                    NeoTestBlock,
                    Space,
                    Git,
                    -- lib.component.compiler_state(),
                },
                winbar = {
                    init = function(self)
                        self.bufnr = vim.api.nvim_get_current_buf()
                    end,
                    Harpoon,
                    Space,
                    FileNameBlock,
                    -- lib.component.breadcrumbs(),
                },
                statuscolumn = {
                    lib.component.foldcolumn(),
                    lib.component.fill(),
                    lib.component.numbercolumn(),
                    lib.component.signcolumn(),
                },
                -- tabline = {
                --     lib.component.tabline_conditional_padding(),
                --     lib.component.tabline_buffers(),
                --     lib.component.tabline_tabpages(),
                -- },
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
    { 'kyazdani42/nvim-web-devicons', lazy = true },
    {
        'lukas-reineke/indent-blankline.nvim',
        main = 'ibl',
        event = 'BufWinEnter',
        ---@module "ibl"
        ---@type ibl.config
        opts = {
            indent = { char = '▏' },
            exclude = {
                filetypes = {
                    'help',
                    'markdown',
                    'gitcommit',
                    'packer',
                },
                buftypes = { 'terminal', 'nofile' },
            },
            scope = { enabled = false },
        },
        config = function(_, opts)
            require('ibl').setup(opts)

            local hooks = require 'ibl.hooks'
            hooks.register(
                hooks.type.WHITESPACE,
                hooks.builtin.hide_first_space_indent_level
            )
        end,
    },
    {
        'kwkarlwang/bufresize.nvim',
        lazy = true,
        init = function()
            vim.api.nvim_create_autocmd('VimResized', {
                callback = function()
                    require('bufresize').resize()
                end,
            })
        end,
        enabled = false,
    },
    { 'MunifTanjim/nui.nvim', lazy = true },
    {
        'folke/noice.nvim',
        event = 'VeryLazy',
        opts = {
            cmdline = {
                format = {
                    cmdline = { pattern = '^:', icon = ':' },
                },
            },
            -- messages = {
            --     enabled = true, -- enables the Noice messages UI
            --     view = 'notify', -- default view for messages
            --     view_error = 'notify', -- view for errors
            --     view_warn = 'notify', -- view for warnings
            --     view_history = 'messages', -- view for :messages
            --     view_search = 'virtualtext', -- view for search count messages. Set to `false` to disable
            -- },
            lsp = {
                signature = { enabled = true },
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
        config = function(_, opts)
            require('noice').setup(opts)
            vim.api.nvim_set_hl(0, 'NoiceVirtualText', { link = 'NormalFloat' })
            vim.api.nvim_set_hl(
                0,
                'NoiceCmdlinePopupBorder',
                { link = 'TelescopePromptBorder' }
            )
            vim.keymap.set('n', '<M-Enter>', function() -- Alt-Enter
                require('noice').redirect 'Inspect'
            end, { desc = 'Show inspect in popup' })
        end,
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
