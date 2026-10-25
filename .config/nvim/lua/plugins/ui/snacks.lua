local icons = require('conf.icons')

local gh = require('conf.snacks.gh')

---@type LazeSpec
return {
    'disrupted/snacks.nvim',
    main = 'snacks',
    module = 'snacks',
    lazy = false,
    priority = 998,
    init = function()
        ---@diagnostic disable-next-line: global-in-non-module
        _G.dd = function(...)
            Snacks.debug.inspect(...)
        end
        ---@diagnostic disable-next-line: global-in-non-module
        _G.bt = function()
            Snacks.debug.backtrace()
        end
        vim.print = _G.dd

        require('which-key').add({
            {
                '<Leader>h',
                function()
                    Snacks.picker.help({ layout = { preset = 'dropdown' } })
                end,
                desc = 'Help',
                icon = '?',
            },
            {
                '<Leader><Leader>',
                function()
                    local picker = Snacks.picker.buffers({
                        current = true,
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
                                    self:execute('calculate_file_truncate_width')
                                end,
                            },
                        },
                    })

                    if not picker then
                        return
                    end

                    picker.list.win:on('VimResized', function()
                        picker:action('calculate_file_truncate_width')
                    end)
                end,
                desc = 'Buffers',
                icon = '',
            },
            {
                '<Leader>f',
                function()
                    ---@type snacks.picker.Config
                    local source = {}

                    if pcall(require, 'fff') and pcall(require, 'fff-snacks') then
                        source = require('fff-snacks.find_files').source
                        source.formatters = nil
                    else
                        Snacks.notify(
                            'fff unavailable, falling back to builtin smart picker'
                        )
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
                                    self:execute('calculate_file_truncate_width')
                                end,
                            },
                            preview = {
                                on_buf = function(self)
                                    self:execute('calculate_file_truncate_width')
                                end,
                                on_close = function(self)
                                    self:execute('calculate_file_truncate_width')
                                end,
                            },
                        },
                    })
                    local picker = Snacks.picker(source)

                    if not picker then
                        return -- abort if picker was closed
                    end

                    picker.list.win:on('VimResized', function()
                        picker:action('calculate_file_truncate_width')
                    end)
                end,
                desc = 'Files',
                icon = icons.documents.files,
            },
            {
                '<Leader>/',
                function()
                    ---@diagnostic disable-next-line: undefined-field
                    Snacks.picker.grep_interactive()
                end,
                desc = 'Grep',
                icon = '󱎸',
            },
            {
                '<Leader>n',
                function()
                    Snacks.notifier.show_history()
                end,
                desc = 'Notification history',
                icon = '',
            },
            {
                '<Leader>s',
                function()
                    require('conf.snacks.lsp.workspace_symbols').pick()
                end,
                desc = 'LSP workspace symbols',
                icon = '󰙅',
            },
            {
                '<Leader>gi',
                function()
                    Snacks.picker.gh_issue()
                end,
                desc = 'List issues',
                icon = icons.git.issue,
            },
            {
                '<Leader>gp',
                function()
                    Snacks.picker.gh_pr()
                end,
                desc = 'List PRs',
                icon = icons.git.pull_request,
            },
            {
                '<A-d>',
                function()
                    ---@diagnostic disable-next-line: param-type-mismatch
                    Snacks.scratch({ ft = 'lua' })
                end,
                desc = 'Toggle Scratch Buffer',
            },
        })
    end,
    keys = {
        {
            '<C-e>',
            function()
                local explorers = Snacks.picker.get({ source = 'explorer' })
                if not vim.tbl_isempty(explorers) then
                    local picker = explorers[1]
                    if not picker then
                        return
                    end
                    if picker:is_focused() then
                        picker:close()
                    else
                        picker.list.win:focus()
                    end
                    return
                end

                local picker = Snacks.picker.explorer({
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
                                        return win:execute('explorer_add')
                                    end,
                                },
                                r = {
                                    ---@param win snacks.win
                                    function(win)
                                        require('conf.ui').cursor.show()
                                        return win:execute('explorer_rename')
                                    end,
                                },
                                c = {
                                    ---@param win snacks.win
                                    function(win)
                                        require('conf.ui').cursor.show()
                                        return win:execute('explorer_copy')
                                    end,
                                },
                                m = {
                                    ---@param win snacks.win
                                    function(win)
                                        require('conf.ui').cursor.show()
                                        return win:execute('explorer_move')
                                    end,
                                },
                            },
                        },
                    },
                })

                picker.list.win:on(
                    { 'BufEnter', 'WinEnter' },
                    require('conf.ui').cursor.hide,
                    { buf = true, desc = 'Hide cursor' }
                )
                picker.list.win:on(
                    { 'BufLeave', 'WinLeave' },
                    require('conf.ui').cursor.show,
                    { buf = true, desc = 'Show cursor' }
                )
                local augroup =
                    vim.api.nvim_create_augroup('ExplorerCmdline', { clear = true })
                vim.api.nvim_create_autocmd('CmdlineLeave', {
                    group = augroup,
                    callback = function()
                        if vim.api.nvim_get_current_win() == picker.list.win.win then
                            require('conf.ui').cursor.hide()
                        end
                    end,
                    desc = 'Re-hide cursor when leaving cmdline back to explorer',
                })
            end,
            desc = 'Explorer',
        },
        {
            '<C-f>',
            function()
                ---@param cwd string
                ---@return string
                local function cwd_title(cwd)
                    if cwd == vim.g.workspace_root then
                        return '.'
                    end
                    local relpath = assert(vim.fs.relpath(vim.g.workspace_root, cwd))
                    return relpath .. '/'
                end

                ---@param picker snacks.Picker
                ---@param cwd string
                local function refresh_cwd_title(picker, cwd)
                    picker.title = cwd_title(cwd)
                    picker:update_titles()
                end

                ---@param picker snacks.Picker
                local function dir_up(picker)
                    local cwd = picker:cwd()
                    if cwd == vim.g.workspace_root then
                        return
                    end

                    cwd = vim.fs.dirname(cwd)
                    picker:set_cwd(cwd)
                    refresh_cwd_title(picker, cwd)
                    picker:find({ refresh = true })
                end

                ---@param picker snacks.Picker
                ---@param item snacks.picker.Item
                ---@return boolean?
                local function dir_down(picker, item, _action)
                    item = item or picker:current({ resolve = false })
                    if not item then
                        return true
                    end

                    if item.dir then
                        local item_path = Snacks.picker.util.path(item)
                        if item_path then
                            local target = vim.fs.normalize(item_path)
                            picker:set_cwd(target)
                            refresh_cwd_title(picker, target)
                            picker:find({ refresh = true })
                        end
                        return true
                    end
                end

                --- escape Lua pattern chars except *
                ---@param glob string
                ---@return string
                local function glob_to_lua_pattern(glob)
                    local p = glob:gsub('([%^%$%(%)%%%.%[%]%+%-%?])', '%%%1')
                    p = p:gsub('%*', '.*')
                    return '^' .. p .. '$'
                end

                local include_globs = { '.github', '.gitlab-ci.yml', '.env*' }
                local include_patterns = vim.tbl_map(glob_to_lua_pattern, include_globs)

                ---@param name string
                ---@return boolean
                local function matches_include(name)
                    for _, p in ipairs(include_patterns) do
                        if name:match(p) then
                            return true
                        end
                    end
                    return false
                end

                ---@param path string
                ---@return boolean,string
                local function is_hidden_name(path)
                    local name = vim.fs.basename(vim.fs.normalize(path))
                    return name:sub(1, 1) == '.', name
                end

                ---@type string?
                local current_file = vim.api.nvim_buf_get_name(0)
                if current_file == '' then
                    current_file = nil
                end
                ---@return string
                local function buf_parent_dir()
                    if not current_file then
                        return vim.g.workspace_root
                    end
                    return vim.fs.dirname(current_file)
                end

                local start_cwd = buf_parent_dir()

                ---@diagnostic disable-next-line: param-type-mismatch
                Snacks.picker.pick({
                    source = 'files',
                    hidden = true,
                    cwd = start_cwd,
                    title = cwd_title(start_cwd),
                    -- current level only, include dirs + files
                    cmd = 'fd',
                    args = {
                        '--type',
                        'd',
                        '-d',
                        '1',
                    },
                    matcher = {
                        sort_empty = true,
                    },
                    sort = {
                        fields = { 'score:desc', 'dir', 'file', 'idx' },
                    },
                    formatters = {
                        file = { filename_only = true },
                    },
                    transform = function(item)
                        local path = Snacks.picker.util.path(item)
                        if not path then
                            return false
                        end
                        path = vim.fs.normalize(path)

                        local is_hidden, name = is_hidden_name(path)
                        if is_hidden and not matches_include(name) then
                            return false
                        end

                        local stat = vim.uv.fs_stat(path)
                        item.file = path
                        item.dir = stat and stat.type == 'directory' or false
                        item.open = false
                        return item
                    end,
                    on_show = function(picker)
                        if not current_file then
                            return
                        end
                        ---@diagnostic disable-next-line: undefined-field
                        if picker._focused_current_file then
                            return
                        end
                        ---@diagnostic disable-next-line: inject-field
                        picker._focused_current_file = true

                        for item, idx in picker:iter() do
                            local path = Snacks.picker.util.path(item)
                            if path and vim.fs.normalize(path) == current_file then
                                picker.list:view(idx) -- move cursor/selection row to current file
                                return
                            end
                        end
                    end,
                    actions = {
                        dir_up = dir_up,
                        dir_down = dir_down,
                        dir_down_or_open = function(...)
                            return dir_down(...) or Snacks.picker.actions.confirm(...)
                        end,
                    },
                    layout = {
                        preset = 'dropdown',
                        ---@diagnostic disable-next-line: assign-type-mismatch
                        preview = false,
                        layout = {
                            row = 0.3,
                            width = 60,
                            height = 20,
                        },
                    },
                    win = {
                        input = {
                            keys = {
                                ['<C-h>'] = {
                                    'dir_up',
                                    mode = { 'n', 'i' },
                                },
                                ['<C-l>'] = {
                                    'dir_down',
                                    mode = { 'n', 'i' },
                                },
                                ['<CR>'] = {
                                    'dir_down_or_open',
                                    mode = { 'n', 'i' },
                                },
                            },
                        },
                        list = {
                            keys = {
                                ['<C-h>'] = 'dir_up',
                                ['<C-l>'] = 'dir_down',
                                ['<CR>'] = 'dir_down_or_open',
                            },
                        },
                    },
                })
            end,
            desc = 'Files',
        },
        {
            '<C-s>',
            function()
                local cursor = vim.api.nvim_win_get_cursor(0)
                -- alternative: Trouble symbols open pinned=true auto_refresh=true win.relative=win win.position=left
                local picker = Snacks.picker.lsp_symbols({
                    title = 'LSP Document Symbols',
                    keep_parents = true,
                    filter = {
                        nickel = true,
                    },
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
                })

                if not picker then
                    return -- abort if picker was closed
                end

                picker.matcher.task:on(
                    'done',
                    vim.schedule_wrap(function()
                        for symbol in vim.iter(picker:items()):rev() do
                            if
                                require('conf.snacks.lsp.symbols').cursor_in_range(
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
            '<leader>gl',
            function()
                if vim.g.git_repo == require('yadm').config.repo then
                    Snacks.picker.git_status({
                        title = 'YADM status',
                        finder = require('conf.snacks.finder').yadm_status,
                    })
                else
                    Snacks.picker.git_status()
                end
            end,
            desc = 'Git/YADM status',
        },
        {
            '<C-g>',
            function()
                Snacks.picker.git_diff()
            end,
            desc = 'Git hunks',
        },
        {
            '<C-x>',
            function()
                if package.loaded.scope and #vim.api.nvim_list_tabpages() > 1 then
                    require('scope.core').close_buffer({})
                else
                    Snacks.bufdelete()
                end
            end,
            desc = 'Delete buffer',
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
            '<Leader>gy',
            function()
                ---@diagnostic disable-next-line: missing-fields, param-type-mismatch
                Snacks.gitbrowse.open({
                    what = 'permalink',
                    notify = false,
                    open = function(url)
                        vim.fn.setreg('+', url)
                        Snacks.notify({ 'Yanked permlink to clipboard', url })
                    end,
                })
            end,
            mode = { 'n', 'v' },
            desc = 'Yank permalink for Git remote',
        },
        {
            '<Leader>R',
            function()
                Snacks.rename.rename_file()
            end,
            desc = 'Rename current buffer file',
        },
    },
    ---@type snacks.Config
    config = function()
        local opts = {
            scratch = {},
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
                actions = {
                    opencode_send = function(picker)
                        local selected = picker:selected({ fallback = true })
                        if selected and #selected > 0 then
                            local files = {}
                            for _, item in ipairs(selected) do
                                if item.file then
                                    table.insert(files, item.file)
                                end
                            end
                            if #files == 0 then
                                Snacks.notify.warn(
                                    'Please select files to send as context',
                                    { title = 'Agent', icon = '' }
                                )
                                return
                            end
                            picker:close()

                            require('opencode.services.session_runtime').open({
                                new_session = false,
                                focus = 'input',
                                start_insert = true,
                            })

                            local context = require('opencode.context')
                            for _, file in ipairs(files) do
                                context.add_file(file)
                            end
                        end
                    end,
                },
                sources = {
                    gh_issue = vim.tbl_deep_extend('force', gh.issue, {
                        layout = {
                            layout = {
                                backdrop = false,
                                row = 1,
                                width = 0.4,
                                min_width = 80,
                                height = 0.8,
                                border = 'none',
                                box = 'vertical',
                                {
                                    win = 'preview',
                                    title = '{preview}',
                                    height = 0.7,
                                    border = false,
                                },
                                {
                                    box = 'vertical',
                                    border = true,
                                    title = '{title} {flags}',
                                    title_pos = 'center',
                                    {
                                        win = 'input',
                                        height = 1,
                                        border = 'bottom',
                                    },
                                    { win = 'list', border = 'none' },
                                },
                            },
                        },
                        win = {
                            input = {
                                keys = {
                                    ['<C-o>'] = {
                                        'gh_develop',
                                        mode = { 'n', 'i' },
                                    },
                                },
                            },
                            list = {
                                keys = {
                                    ['<C-o>'] = { 'gh_develop' },
                                },
                            },
                        },
                    }),
                    gh_pr = vim.tbl_deep_extend('force', gh.pr, {
                        layout = {
                            layout = {
                                backdrop = false,
                                row = 1,
                                width = 0.4,
                                min_width = 80,
                                height = 0.8,
                                border = 'none',
                                box = 'vertical',
                                {
                                    win = 'preview',
                                    title = '{preview}',
                                    height = 0.7,
                                    border = false,
                                },
                                {
                                    box = 'vertical',
                                    border = true,
                                    title = '{title} {flags}',
                                    title_pos = 'center',
                                    {
                                        win = 'input',
                                        height = 1,
                                        border = 'bottom',
                                    },
                                    { win = 'list', border = 'none' },
                                },
                            },
                        },
                        win = {
                            input = {
                                keys = {
                                    ['<C-o>'] = {
                                        'gh_checkout_pr',
                                        mode = { 'n', 'i' },
                                    },
                                },
                            },
                            list = {
                                keys = {
                                    ['<C-o>'] = { 'gh_checkout_pr' },
                                },
                            },
                        },
                    }),
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
                                        mode = { 'i' },
                                    },
                                    ['<CR>'] = {
                                        { 'pick_win', 'jump' },
                                        mode = { 'n', 'i' },
                                    },
                                },
                            },
                            list = {
                                keys = {
                                    ['<Esc>'] = { 'explorer_update' },
                                },
                            },
                        },
                    },
                    dirs = {
                        finder = function(fopts, ctx)
                            local finder = require('conf.snacks.finder')
                            return vim.g.git_repo and finder.git_dirs(fopts, ctx)
                                or finder.fd_dirs(fopts, ctx)
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
                                ---@diagnostic disable-next-line: param-type-mismatch
                                Snacks.input.input({
                                    prompt = 'Grep glob',
                                    default = default,
                                }, function(input)
                                    if not input or input == '' or input == default then
                                        return
                                    end
                                    table.insert(self.opts['glob'], input)
                                    self:find()
                                end)
                            end,
                            pick_dirs = function(self, _, _)
                                self.input.filter.meta.grep_search = self.input:get()
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
                                    self:action('confirm')
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
                            preset = 'dropdown',
                            layout = {
                                width = 0.8,
                                max_width = 200,
                            },
                        },
                    },
                    lsp_supertypes = {
                        title = 'LSP Supertypes',
                        finder = require('conf.snacks.lsp.type_hierarchy').supertypes,
                        format = require('conf.snacks.lsp.type_hierarchy').format_lsp_symbol,
                        workspace = true,
                        jump = { tagstack = true, reuse_win = true },
                        layout = {
                            preset = 'select',
                            layout = { max_height = 14 },
                        },
                    },
                    lsp_declarations = {
                        title = 'LSP Declarations',
                        layout = {
                            preset = 'select',
                            layout = { max_height = 14 },
                        },
                    },
                    lsp_definitions = {
                        title = 'LSP Definitions',
                        finder = require('conf.snacks.lsp.definitions_filtered').finder,
                        layout = {
                            preset = 'select',
                            layout = { max_height = 14 },
                        },
                    },
                    lsp_implementations = {
                        title = 'LSP Implementation',
                        layout = {
                            preset = 'select',
                            layout = { max_height = 14 },
                        },
                    },
                    lsp_references = {
                        title = 'LSP References',
                        layout = {
                            preset = 'dropdown',
                            preview = true,
                            layout = {
                                relative = 'cursor',
                                width = 130,
                                max_width = 180,
                                max_height = 20,
                                row = 1,
                                col = -10,
                            },
                        },
                    },
                    lsp_type_definitions = {
                        title = 'LSP Type Definitions',
                        layout = {
                            preset = 'select',
                        },
                    },
                    lsp_incoming_calls = {
                        title = 'LSP Incoming Calls',
                        layout = {
                            preset = 'select',
                        },
                    },
                    lsp_outgoing_calls = {
                        title = 'LSP Outgoing Calls',
                        layout = {
                            preset = 'select',
                        },
                    },
                    lsp_subtypes = {
                        title = 'LSP Subtypes',
                        finder = require('conf.snacks.lsp.type_hierarchy').subtypes,
                        format = require('conf.snacks.lsp.type_hierarchy').format_lsp_symbol,
                        workspace = true,
                        jump = { tagstack = true, reuse_win = true },
                        layout = {
                            preset = 'select',
                            layout = { max_height = 14 },
                        },
                    },
                },
                layouts = {
                    select = {
                        layout = {
                            relative = 'cursor',
                            width = 130,
                            max_width = 180,
                            max_height = 14,
                            row = 1,
                            col = -10,
                        },
                    },
                },
                layout = {
                    cycle = true,
                    preset = function()
                        return vim.o.columns >= 120 and 'telescope' or 'dropdown'
                    end,
                },
                win = {
                    input = {
                        keys = {
                            ['<C-a>'] = {
                                'opencode_send',
                                mode = { 'n', 'i' },
                            },
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
        }
        ---@diagnostic disable-next-line: param-type-mismatch
        require('snacks').setup(opts)

        local gh_actions = require('snacks.gh.actions')
        gh_actions.actions.gh_merge_rebase = {
            enabled = function()
                return false
            end,
        }
        gh_actions.actions.gh_merge = {
            enabled = function()
                return false
            end,
        }
        gh_actions.actions.gh_develop = gh_actions.cli_action({
            cmd = 'develop',
            icon = icons.git.branch .. ' ',
            type = 'issue',
            args = { '--checkout' },
            title = 'Create branch for issue #{number}',
            success = 'Created and checked out branch for issue #{number}',
            enabled = function(item)
                return item.state == 'open'
            end,
        })
        gh_actions.actions.gh_checkout_pr = {
            title = 'Checkout PR #{number}',
            icon = gh_actions.cli_actions.gh_checkout.icon,
            type = 'pr',
            action = function(item, ctx)
                -- checkout PR without confirmation dialog
                local checkout = gh_actions.cli_actions.gh_checkout
                gh_actions.run(item, {
                    cmd = checkout.cmd,
                    icon = checkout.icon,
                    type = checkout.type,
                    title = checkout.title,
                    success = checkout.success,
                }, ctx)
            end,
        }

        -- remap submit for consistency and to avoid conflict with blink.cmp
        local scratch_open = Snacks.scratch.open
        ---@param scratch_opts? snacks.scratch.Config
        Snacks.scratch.open = function(scratch_opts)
            local win = (scratch_opts or {}).win
            if win and win.keys and win.keys.submit then
                win.keys.submit[1] = '<S-CR>'
                local footer_keys = win.footer_keys
                if type(footer_keys) == 'table' then
                    for i, key in ipairs(footer_keys) do
                        if key == '<c-s>' then
                            footer_keys[i] = '<S-CR>'
                        end
                    end
                end
            end
            return scratch_open(scratch_opts)
        end

        -- Snacks hardcodes a list of commit types (chore, bot, build, ci,
        -- style, test) whose subject is rendered with `SnacksPickerDimmed`.
        -- Neutralize it so no commit type is dimmed. Covers gh pickers,
        -- `git log`, diff headers and the gh preview.
        local format = require('snacks.picker.format')
        local commit_message = format.commit_message
        ---@param item snacks.picker.Item
        ---@param picker snacks.Picker
        ---@diagnostic disable-next-line: duplicate-set-field
        format.commit_message = function(item, picker)
            local ret = commit_message(item, picker)
            for _, span in ipairs(ret) do
                if span[2] == 'SnacksPickerDimmed' then
                    span[2] = 'SnacksPickerGitMsg'
                end
            end
            return ret
        end
    end,
}
