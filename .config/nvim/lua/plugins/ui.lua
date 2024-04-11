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
        opts = function()
            local conditions = require 'heirline.conditions'
            local utils = require 'heirline.utils'

            local colors = require('one.colors').get()
            require('heirline').load_colors(colors)

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
                provider = function()
                    local icon = '  '
                    local cwd = vim.loop.cwd()
                    cwd = vim.fn.fnamemodify(cwd, ':~')
                    -- if not conditions.width_percent_below(#cwd, 0.25) then
                    --     cwd = vim.fn.pathshorten(cwd)
                    -- end
                    return icon .. cwd
                end,
                hl = {
                    fg = 'mono_1',
                    bg = 'syntax_cursor',
                    bold = true,
                },
            }

            local FileNameBlock = {
                init = function(self)
                    self.filename = vim.api.nvim_buf_get_name(0)
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
                provider = function(self)
                    return self.icon and (self.icon .. ' ')
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
                local bt = vim.api.nvim_buf_get_option(bufnr, 'buftype')
                return bt ~= 'nofile' and bt ~= 'terminal'
            end

            local FilePath = {
                provider = function(self)
                    local bufnr = vim.api.nvim_win_get_buf(0)
                    if not is_file(bufnr) then
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
                    -- hl = { fg = 'green' },
                },
                {
                    condition = function()
                        return not vim.bo.modifiable or vim.bo.readonly
                    end,
                    provider = '',
                    -- hl = { fg = 'orange' },
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

                init = function(self)
                    self.status_dict = vim.b.gitsigns_status_dict ---@diagnostic disable-line: undefined-field
                    self.has_changes = self.status_dict.added ~= 0
                        or self.status_dict.removed ~= 0
                        or self.status_dict.changed ~= 0
                end,

                {
                    provider = function(self)
                        local count = self.status_dict.added or 0
                        return count > 0 and ('+' .. count)
                    end,
                    hl = {
                        fg = 'hue_4',
                        bg = 'syntax_cursor',
                    },
                },
                Space,
                {
                    provider = function(self)
                        local count = self.status_dict.changed or 0
                        return count > 0 and ('~' .. count)
                    end,
                    hl = {
                        fg = 'hue_6_2',
                        bg = 'syntax_cursor',
                    },
                },
                Space,
                {
                    provider = function(self)
                        local count = self.status_dict.removed or 0
                        return count > 0 and ('-' .. count)
                    end,
                    hl = {
                        fg = 'hue_5',
                        bg = 'syntax_cursor',
                    },
                },
                Space,
                { -- git branch name
                    provider = function(self)
                        return ' ' .. self.status_dict.head
                    end,
                    hl = { bold = false },
                },
            }

            local Diagnostics = {

                condition = conditions.has_diagnostics,

                static = {
                    error_icon = ' ',
                    warn_icon = ' ',
                    info_icon = ' ',
                },

                hl = { bg = 'syntax_cursor' },

                init = function(self)
                    self.errors = #vim.diagnostic.get(
                        0,
                        { severity = vim.diagnostic.severity.ERROR }
                    )
                    self.warnings = #vim.diagnostic.get(
                        0,
                        { severity = vim.diagnostic.severity.WARN }
                    )
                    self.hints = #vim.diagnostic.get(
                        0,
                        { severity = vim.diagnostic.severity.HINT }
                    )
                    self.info = #vim.diagnostic.get(
                        0,
                        { severity = vim.diagnostic.severity.INFO }
                    )
                end,

                update = { 'DiagnosticChanged', 'BufEnter' },

                {
                    provider = function(self)
                        -- 0 is just another output, we can decide to print it or not!
                        return self.errors > 0
                            and (self.error_icon .. self.errors .. ' ')
                    end,
                    hl = {
                        fg = 'hue_5',
                        bg = 'syntax_cursor',
                    },
                },
                {
                    provider = function(self)
                        return self.warnings > 0
                            and (self.warn_icon .. self.warnings .. ' ')
                    end,
                    hl = {
                        fg = 'hue_6_2',
                        bg = 'syntax_cursor',
                    },
                },
                {
                    provider = function(self)
                        return self.info > 0
                            and (self.info_icon .. self.info .. ' ')
                    end,
                    hl = {
                        fg = 'hue_2',
                        bg = 'syntax_cursor',
                    },
                },
            }

            local Harpoon = {
                provider = function()
                    local harpoon = require 'harpoon'
                    local list = harpoon:list()

                    local name = vim.fn.expand '%'
                    local item = list:get_by_value(name)

                    if not item then
                        return
                    end
                    return 'M'
                end,
            }

            local DAPMessages = {
                condition = function()
                    local session = require('dap').session()
                    return session ~= nil
                end,
                provider = function()
                    return ' ' .. require('dap').status()
                end,
            }

            local StatusLine = {
                WorkDir,
                Space,
                Diagnostics,
                Align,
                Align,
                DAPMessages,
                Space,
                Git,
            }

            local WinBar = {
                Harpoon,
                Space,
                FileNameBlock,
            }

            return {
                statusline = StatusLine,
                winbar = WinBar,
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
                hover = { enabled = false, silent = true },
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
}
