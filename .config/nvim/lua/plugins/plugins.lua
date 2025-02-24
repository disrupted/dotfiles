---@module 'lazy.types'
---@type LazySpec[]
return {
    'nvim-lua/plenary.nvim',
    { 'gregorias/coop.nvim', lazy = true }, -- concurrency with coroutines
    {
        'folke/snacks.nvim',
        priority = 1000,
        lazy = false,
        init = function()
            _G.dd = function(...)
                Snacks.debug.inspect(...)
            end
            _G.bt = function()
                Snacks.debug.backtrace()
            end
            vim.print = _G.dd
        end,
        keys = {
            {
                '<leader><leader>',
                function()
                    Snacks.picker.buffers {
                        layout = { preset = 'dropdown' },
                        current = false,
                    }
                end,
                desc = 'Buffers',
            },
            {
                '<C-e>',
                function()
                    if
                        package.loaded.dapui
                        and require('dapui.windows').layouts[1]:is_open()
                    then
                        require('dapui').close()
                    end

                    local picker = Snacks.picker.explorer {
                        layout = {
                            preset = 'sidebar',
                            preview = false,
                            fullscreen = false,
                        },
                        jump = { close = false },
                        include = { '.github', '.env*' },
                        -- on_close = function(_)
                        --     if require('dapui.windows').layouts[1]:is_open() then
                        --         require('dapui').open { reset = true }
                        --     end
                        -- end,
                        -- win = {
                        --     list = {
                        --         keys = {
                        --             ['<CR>'] = { { 'pick_win', 'jump' } }, -- FIXME: cannot open/close directories anymore
                        --         },
                        --     },
                        -- },
                    }

                    if not picker then
                        return -- abort if picker was closed
                    end

                    picker.list.win:on(
                        'BufEnter',
                        require('conf.ui').cursor.hide,
                        { buf = true, desc = 'Hide cursor' }
                    )

                    picker.list.win:on(
                        'BufLeave',
                        require('conf.ui').cursor.show,
                        { buf = true, desc = 'Show cursor' }
                    )
                end,
                desc = 'Explorer',
            },
            {
                '<C-f>',
                function()
                    local picker = Snacks.picker.smart {
                        finders = {
                            'buffers',
                            'recent',
                            require('git').is_repo() and 'git_files' or 'files',
                        },
                        hidden = true,
                        matcher = { sort_empty = true },
                        filter = {
                            cwd = true,
                        },
                        layout = { preset = 'telescope', reverse = true },
                        actions = {
                            calculate_file_truncate_width = function(self)
                                local width = self.list.win:size().width
                                self.opts.formatters.file.truncate = width - 6
                            end,
                        },
                        win = {
                            list = {
                                on_buf = function(self)
                                    self:execute 'calculate_file_truncate_width'
                                end,
                            },
                            preview = {
                                on_buf = function(self)
                                    self:execute 'calculate_file_truncate_width'
                                end,
                                on_close = function(self)
                                    self:execute 'calculate_file_truncate_width'
                                end,
                            },
                        },
                    }

                    picker.list.win:on('VimResized', function()
                        picker:action 'calculate_file_truncate_width'
                    end)
                end,
                desc = 'Files',
            },
            {
                '<leader>/',
                function()
                    ---@diagnostic disable-next-line: undefined-field
                    Snacks.picker.grep_interactive()
                end,
                desc = 'Grep',
            },
            {
                '<C-s>',
                function()
                    local cursor = vim.api.nvim_win_get_cursor(0)
                    local picker = Snacks.picker.lsp_symbols {
                        title = 'LSP Document Symbols',
                        layout = {
                            preset = 'dropdown',
                            preview = 'main',
                        },
                        win = {
                            preview = {
                                wo = { number = true },
                            },
                        },
                    }

                    picker.matcher.task:on(
                        'done',
                        vim.schedule_wrap(function()
                            for symbol in vim.iter(picker:items()):rev() do
                                if
                                    require('conf.snacks.lsp_symbols').cursor_in_range(
                                        cursor,
                                        symbol.range
                                    )
                                then
                                    picker.list:move(symbol.idx, true)
                                    return
                                end
                            end
                        end)
                    )
                end,
                desc = 'LSP symbols',
            },
            {
                '<leader>s',
                function()
                    Snacks.picker.lsp_workspace_symbols {
                        title = 'LSP Workspace Symbols',
                        layout = {
                            preset = 'dropdown',
                            layout = { width = 0.5 },
                        },
                    }
                end,
                desc = 'LSP workspace symbols',
            },
            {
                '<C-g>',
                function()
                    if require('git').is_repo() then
                        Snacks.picker.git_status()
                    else
                        Snacks.picker.git_status {
                            title = 'YADM status',
                            finder = require('conf.snacks.finder').yadm_status,
                            preview = require('conf.snacks.preview').yadm_status,
                        }
                    end
                end,
                desc = 'Git/YADM status',
            },
            {
                ',h',
                function()
                    Snacks.picker.help { layout = { preset = 'dropdown' } }
                end,
                desc = 'Help',
            },
            {
                '<C-x>',
                function()
                    Snacks.bufdelete()
                end,
                desc = 'Delete buffer',
            },
            {
                '<leader>n',
                function()
                    Snacks.notifier.show_history()
                end,
                desc = 'Show notification history',
            },
            {
                '\\',
                function()
                    Snacks.terminal()
                end,
            },
            {
                '<C-n>',
                function()
                    Snacks.words.jump(vim.v.count1)
                end,
                desc = 'Next reference',
            },
            {
                '<C-p>',
                function()
                    Snacks.words.jump(-vim.v.count1)
                end,
                desc = 'Prev reference',
            },
            {
                '<leader>gl',
                function()
                    Snacks.gitbrowse.open {
                        notify = false,
                        open = function(url)
                            vim.fn.setreg('+', url)
                            Snacks.notify { 'Yanked permlink to clipboard', url }
                        end,
                    }
                end,
                mode = { 'n', 'v' },
                desc = 'Yank permalink for Git remote',
            },
        },
        ---@type snacks.Config
        opts = {
            bigfile = { enabled = true },
            explorer = {},
            gitbrowse = {},
            indent = {
                filter = function(buf)
                    return vim.g.snacks_indent ~= false
                        and vim.b[buf].snacks_indent ~= false
                        and vim.bo[buf].buftype == ''
                        and not vim.tbl_contains({
                            'markdown',
                            'gitcommit',
                        }, vim.bo[buf].filetype)
                end,
                indent = {
                    char = '▏',
                    hl = {
                        'Hidden', -- first one blends with background
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                        'Whitespace',
                    },
                },
                animate = {
                    duration = {
                        step = 15,
                        total = 300,
                    },
                },
                scope = {
                    enabled = false,
                    only_current = true,
                    hl = 'NonText',
                    char = '▏',
                },
                chunk = {
                    enabled = true,
                    only_current = true,
                    hl = 'NonText',
                    char = {
                        corner_top = '┌',
                        corner_bottom = '└',
                        horizontal = '─',
                        vertical = '│', --│▕
                        arrow = '󰁔', --   󰁔  
                    },
                },
            },
            image = {
                enabled = true,
                markdown = { inline = false, float = true },
            },
            input = { enabled = true },
            notifier = {
                enabled = true,
                level = vim.log.levels.INFO,
                width = { min = 10, max = 0.4 },
                icons = {
                    error = '',
                    warn = '',
                    info = '',
                    debug = '',
                    trace = '',
                },
            },
            statuscolumn = { enabled = true },
            picker = {
                ui_select = true,
                sources = {
                    explorer = {
                        layout = {
                            fullscreen = true,
                            layout = { backdrop = false, relative = 'win' },
                        },
                        jump = { close = true },
                        win = {
                            input = {
                                keys = {
                                    ['<Esc>'] = {
                                        'toggle_focus',
                                        mode = { 'i', 'n' },
                                    },
                                    ['<CR>'] = {
                                        { 'pick_win', 'jump' },
                                        mode = { 'n', 'i' },
                                    },
                                },
                            },
                            list = {
                                keys = {
                                    ['<Esc>'] = 'toggle_focus',
                                },
                            },
                        },
                    },
                    dirs = {
                        finder = function(opts, ctx)
                            local finder = require 'conf.snacks.finder'
                            return require('git').is_repo()
                                    and finder.git_dirs(opts, ctx)
                                or finder.fd_dirs(opts, ctx)
                        end,
                        format = 'file',
                        show_empty = true,
                        hidden = false,
                        ignored = false,
                        follow = false,
                        supports_live = true,
                    },
                    grep_interactive = {
                        multi = { 'grep', 'dirs' },
                        glob = {},
                        dirs = {},
                        filter = {
                            ---@param picker snacks.Picker
                            ---@param filter snacks.picker.Filter
                            transform = function(picker, filter)
                                local source_id = filter.meta.source_id or 1
                                filter.source_id = source_id
                                if source_id == 1 then
                                    picker.title = 'Grep'
                                    picker.opts.show_empty = true
                                    picker.opts.live = true
                                else
                                    picker.title = 'Grep dirs'
                                    picker.opts.show_empty = false
                                    picker.opts.live = false
                                end
                            end,
                        },
                        actions = {
                            pick_glob = function(self, _)
                                local default = '*.'
                                Snacks.input.input({
                                    prompt = 'Grep glob',
                                    default = default,
                                }, function(
                                    input
                                )
                                    if
                                        not input
                                        or input == ''
                                        or input == default
                                    then
                                        return
                                    end
                                    table.insert(self.opts['glob'], input)
                                    self:find()
                                end)
                            end,
                            pick_dirs = function(self, _, _)
                                self.input.filter.meta.source_id = 2
                                -- FIXME: reset input search
                                -- self.input.filter.search = ''
                                self:find()
                            end,
                            confirm_custom = function(self, item, _)
                                if not item then
                                    return
                                end
                                if item.source_id == 2 then
                                    table.insert(self.opts['dirs'], item.file)
                                    self.input.filter.meta.source_id = 1
                                    -- FIXME: reset input search
                                    -- self.input.filter.search = ''
                                    self:find()
                                else
                                    self:action 'confirm'
                                end
                            end,
                        },
                        win = {
                            input = {
                                keys = {
                                    ['<c-e>'] = {
                                        'pick_glob',
                                        mode = { 'i', 'n' },
                                        desc = 'Filter grep extension',
                                    },
                                    ['<c-d>'] = {
                                        'pick_dirs',
                                        mode = { 'i', 'n' },
                                        desc = 'Filter grep directory',
                                    },
                                    ['<CR>'] = {
                                        'confirm_custom',
                                        mode = { 'i', 'n' },
                                        desc = 'Confirm',
                                    },
                                },
                            },
                        },
                        layout = {
                            preset = 'telescope',
                            reverse = true,
                        },
                    },
                },
                layouts = {
                    select = {
                        layout = {
                            relative = 'cursor',
                            width = 70,
                            min_width = 0,
                            row = 1,
                        },
                    },
                },
                win = {
                    input = {
                        keys = {
                            ['<Esc>'] = {
                                'close',
                                mode = { 'i', 'n' },
                                desc = 'Close',
                            },
                        },
                    },
                    preview = { minimal = true },
                },
                icons = {
                    git = require('conf.icons').git,
                    diagnostics = { Hint = '' },
                    kinds = require('conf.icons').kinds,
                },
            },
            terminal = {
                keys = { ['\\'] = 'hide' },
            },
            words = { enabled = true },
            styles = {
                ---@diagnostic disable-next-line: missing-fields
                notification_history = {
                    keys = { ['<Esc>'] = 'close' },
                },
            },
        },
    },
    { 'tpope/vim-repeat', event = 'VeryLazy' },
    { 'jghauser/mkdir.nvim', event = 'BufWritePre' },
    {
        'NMAC427/guess-indent.nvim',
        cmd = 'GuessIndent',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {},
    },
    {
        'folke/which-key.nvim',
        event = 'VeryLazy',
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 500
        end,
        opts = {},
    },
    {
        'rest-nvim/rest.nvim',
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
            opts = function(_, opts)
                opts.ensure_installed = opts.ensure_installed or {}
                table.insert(opts.ensure_installed, 'http')
            end,
        },
        main = 'rest-nvim',
        ft = 'http',
        keys = {
            {
                '<localleader>rr',
                '<cmd>Rest run<cr>',
                desc = 'Run request under the cursor',
            },
            {
                '<localleader>rl',
                '<cmd>Rest run last<cr>',
                desc = 'Re-run latest request',
            },
        },
        ---@module 'rest-nvim.config'
        ---@type rest.Opts
        opts = {},
    },
    { 'mrjones2014/op.nvim', build = 'make install', lazy = true },
}
