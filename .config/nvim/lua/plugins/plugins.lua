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

            require('which-key').add {
                { '<Leader>h', icon = '?' },
                { '<Leader><Leader>', icon = '' },
                { '<Leader>/', icon = '󱎸' },
                { '<Leader>n', icon = '' },
                { '<Leader>s', icon = '󰙅' },
            }
        end,
        keys = {
            {
                '<Leader><Leader>',
                function()
                    local picker = Snacks.picker.buffers {
                        current = false,
                        sort_lastused = true,
                        layout = {
                            preset = 'dropdown',
                            ---@diagnostic disable-next-line: assign-type-mismatch
                            preview = false, -- disable preview because it messes up lastused sorting
                            layout = {
                                row = 0.1,
                                width = 0.4,
                                min_width = 80,
                                height = 0.4,
                            },
                        },
                        actions = {
                            calculate_file_truncate_width = function(self)
                                local width = self.list.win:size().width
                                self.opts.formatters.file.truncate = width - 18
                            end,
                        },
                        win = {
                            list = {
                                on_buf = function(self)
                                    self:execute 'calculate_file_truncate_width'
                                end,
                            },
                        },
                    }

                    if not picker then
                        return
                    end

                    picker.list.win:on('VimResized', function()
                        picker:action 'calculate_file_truncate_width'
                    end)
                end,
                desc = 'Buffers',
            },
            {
                '<C-e>',
                function()
                    local explorers = Snacks.picker.get { source = 'explorer' }
                    if not vim.tbl_isempty(explorers) then
                        local picker = explorers[1]
                        if picker:is_focused() then
                            picker:close()
                        else
                            picker.list.win:focus()
                        end
                        return
                    end

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
                        include = { '.github', '.gitlab-ci.yml', '.env*' },
                        -- on_close = function(_)
                        --     if require('dapui.windows').layouts[1]:is_open() then
                        --         require('dapui').open { reset = true }
                        --     end
                        -- end,
                        win = {
                            list = {
                                keys = {
                                    -- ['<CR>'] = { { 'pick_win', 'jump' } }, -- FIXME: cannot open/close directories anymore
                                    a = {
                                        ---@param win snacks.win
                                        function(win)
                                            require('conf.ui').cursor.show()
                                            return win:execute 'explorer_add'
                                        end,
                                    },
                                    r = {
                                        ---@param win snacks.win
                                        function(win)
                                            require('conf.ui').cursor.show()
                                            return win:execute 'explorer_rename'
                                        end,
                                    },
                                    c = {
                                        ---@param win snacks.win
                                        function(win)
                                            require('conf.ui').cursor.show()
                                            return win:execute 'explorer_copy'
                                        end,
                                    },
                                    m = {
                                        ---@param win snacks.win
                                        function(win)
                                            require('conf.ui').cursor.show()
                                            return win:execute 'explorer_move'
                                        end,
                                    },
                                },
                            },
                        },
                    }

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
                    ---@type snacks.picker.Config
                    local source = {}

                    local fff_exists = pcall(require, 'fff-snacks')
                    if fff_exists then
                        source = require('fff-snacks').source
                        source.formatters = nil
                    else
                        Snacks.notify 'fff unavailable, falling back to builtin smart picker'
                        source = {
                            source = 'smart',
                            finders = {
                                'buffers',
                                'recent',
                                vim.g.git_repo and 'git_files' or 'files',
                            },
                            hidden = true,
                            matcher = { sort_empty = true },
                            filter = { cwd = true },
                        }
                    end

                    source = vim.tbl_deep_extend('force', source, {
                        title = 'Files',
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
                    })
                    local picker = Snacks.picker(source)

                    if not picker then
                        return -- abort if picker was closed
                    end

                    picker.list.win:on('VimResized', function()
                        picker:action 'calculate_file_truncate_width'
                    end)
                end,
                desc = 'Files',
            },
            {
                '<Leader>/',
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
                    -- alternative: Trouble symbols open pinned=true auto_refresh=true win.relative=win win.position=left
                    local picker = Snacks.picker.lsp_symbols {
                        title = 'LSP Document Symbols',
                        focus = 'list',
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

                    if not picker then
                        return -- abort if picker was closed
                    end

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
                '<Leader>s',
                function()
                    ---@return boolean
                    local function has_workspace_symbol_client()
                        return not vim.tbl_isempty(
                            vim.lsp.get_clients { method = 'workspace/symbol' }
                        )
                    end

                    local function start_workspace_clients()
                        local workspace = require 'conf.workspace'
                        local filetypes =
                            workspace.project_filetypes { buffers = false }
                        for _, filetype in ipairs(filetypes) do
                            require('conf.workspace.lsp').start(filetype)
                        end
                    end

                    if not has_workspace_symbol_client() then
                        start_workspace_clients()
                    end

                    local picker = Snacks.picker.lsp_workspace_symbols {
                        title = 'LSP Workspace Symbols',
                        matcher = {
                            fuzzy = true,
                            ignorecase = false,
                            smartcase = true,
                        },
                        layout = {
                            preset = 'dropdown',
                            layout = { width = 0.5 },
                        },
                        actions = {
                            toggle_live_match = function(self, _)
                                if self.opts.live then
                                    -- apply search as pattern
                                    local search = self.input:get()
                                    self.input:set(search)
                                end
                                self:action 'toggle_live'
                            end,
                        },
                        win = {
                            input = {
                                keys = {
                                    ['<C-g>'] = {
                                        'toggle_live_match',
                                        mode = { 'i', 'n' },
                                        desc = 'Toggle live, apply live search as match pattern',
                                    },
                                },
                            },
                        },
                    }

                    if not picker then
                        return -- abort if picker was closed
                    end

                    picker.input.win:on(
                        { 'TextChangedI', 'TextChanged' },
                        function(win)
                            if not win:valid() then
                                return
                            end
                            if picker.opts.live then
                                -- apply search as pattern
                                picker.input.filter.pattern =
                                    picker.input.filter.search
                            end
                        end,
                        { buf = true }
                    )

                    -- give LSP some time to start
                    vim.defer_fn(function()
                        if not has_workspace_symbol_client() then
                            Snacks.notify.warn 'No client supporting workspace symbols'
                        end
                    end, 1000)
                end,
                desc = 'LSP workspace symbols',
            },
            {
                '<C-g>',
                function()
                    if vim.g.git_repo == require('yadm').config.repo then
                        Snacks.picker.git_status {
                            title = 'YADM status',
                            finder = require('conf.snacks.finder').yadm_status,
                        }
                    else
                        Snacks.picker.git_status()
                    end
                end,
                desc = 'Git/YADM status',
            },
            {
                '<Leader>h',
                function()
                    Snacks.picker.help { layout = { preset = 'dropdown' } }
                end,
                desc = 'Help',
            },
            {
                '<C-x>',
                function()
                    if
                        package.loaded.scope
                        and #vim.api.nvim_list_tabpages() > 1
                    then
                        require('scope.core').close_buffer {}
                    else
                        Snacks.bufdelete()
                    end
                end,
                desc = 'Delete buffer',
            },
            {
                '<Leader>n',
                function()
                    Snacks.notifier.show_history()
                end,
                desc = 'Notification history',
            },
            {
                '<C-Bslash>',
                function()
                    Snacks.terminal()
                end,
                mode = { 'n', 't', 'i', 'v' },
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
                '<Leader>gl',
                function()
                    ---@diagnostic disable-next-line: missing-fields
                    Snacks.gitbrowse.open {
                        what = 'permalink',
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
                enabled = false,
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
                        -- layout = {
                        --     fullscreen = true,
                        --     layout = { backdrop = false, relative = 'win' },
                        -- },
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
                            return vim.g.git_repo and finder.git_dirs(opts, ctx)
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
                                self.input.filter.meta.grep_search =
                                    self.input:get()
                                self.input:set(nil, '')
                                self.input.filter.meta.source_id = 2
                                self:find()
                            end,
                            confirm_custom = function(self, item, _)
                                if not item then
                                    return
                                end
                                if item.source_id == 2 then
                                    table.insert(self.opts['dirs'], item.file)
                                    self.input.filter.meta.source_id = 1
                                    self:find()
                                    self.input:set(
                                        '',
                                        self.input.filter.meta.grep_search
                                    )
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
                layout = {
                    cycle = true,
                    preset = function()
                        return vim.o.columns >= 120 and 'telescope'
                            or 'dropdown'
                    end,
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
                ---@diagnostic disable-next-line: missing-fields
                icons = {
                    git = require('conf.icons').git,
                    diagnostics = { Hint = '' },
                    kinds = require('conf.icons').kinds,
                },
            },
            terminal = {
                -- keys = { ['\\'] = 'hide' },
                win = {
                    wo = {
                        winbar = '',
                    },
                },
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
    {
        'dmtrKovalenko/fff.nvim',
        lazy = true,
        build = function()
            require('fff.download').download_binary()
        end,
        opts = {},
    },
    {
        'madmaxieee/fff-snacks.nvim',
        lazy = true,
        dependencies = {
            'dmtrKovalenko/fff.nvim',
            'folke/snacks.nvim',
        },
        opts = {},
    },
    {
        'tpope/vim-repeat',
        event = 'VeryLazy',
        keys = {
            { '<Nop>', '<Plug>(RepeatUndo)' },
            { '<Nop>', '<Plug>(RepeatUndoLine)' },
        },
    },
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
        keys = {
            {
                '<Leader>?',
                function()
                    require('which-key').show { global = false }
                end,
                desc = 'Buffer-local keymaps (which-key)',
            },
        },
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 500
        end,
        ---@module 'which-key.config'
        ---@type wk.Opts
        ---@diagnostic disable-next-line: missing-fields
        opts = {
            preset = 'helix',
            ---@param mapping wk.Mapping
            filter = function(mapping)
                -- exclude mappings without a description
                return mapping.desc and mapping.desc ~= ''
            end,
            spec = {
                { '<Leader>?', hidden = true },
                -- override motions preset
                { ',', desc = '' },
                { ';', desc = '' },
            },
            icons = {
                rules = {
                    {
                        plugin = 'opencode-native',
                        icon = ' ',
                        color = 'yellow',
                    },
                    {
                        plugin = 'opencode-native',
                        pattern = 'reasoning',
                        icon = '󱍎 ',
                    },
                    {
                        plugin = 'opencode-native',
                        pattern = 'tool',
                        icon = ' ',
                    },
                },
            },
        },
    },
    {
        'rest-nvim/rest.nvim',
        main = 'rest-nvim',
        cmd = 'Rest',
        keys = {
            { -- which-key group
                '<LocalLeader>r',
                nil,
                ft = 'http',
                desc = 'Request (rest.nvim)',
            },
            {
                '<LocalLeader>rr',
                '<cmd>Rest run<cr>',
                ft = 'http',
                desc = 'Run',
            },
            {
                '<LocalLeader>rl',
                '<cmd>Rest run last<cr>',
                ft = 'http',
                desc = 'Re-run last',
            },
        },
        ---@module 'rest-nvim.config'
        ---@type rest.Opts
        opts = {},
    },
    { 'mrjones2014/op.nvim', build = 'make install', lazy = true },
    {
        -- 'sotte/presenting.nvim',
        'gerazov/presenting.nvim',
        branch = 'add_title_to_footer',
        cmd = 'Presenting',
        opts = {},
    },
}
