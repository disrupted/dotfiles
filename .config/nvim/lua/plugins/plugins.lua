return {
    'nvim-lua/plenary.nvim',
    {
        'folke/snacks.nvim',
        priority = 1000,
        lazy = false,
        keys = {
            {
                '<leader><leader>',
                function()
                    ---@diagnostic disable-next-line: missing-fields
                    Snacks.picker.buffers {
                        layout = { preset = 'dropdown' },
                        current = false,
                    }
                end,
                desc = 'Buffers',
            },
            {
                '<C-f>',
                function()
                    Snacks.picker.smart {
                        finders = {
                            'buffers',
                            'recent',
                            vim.uv.fs_stat '.git' and 'git_files' or 'files',
                        },
                        format = 'file',
                        matcher = { sort_empty = true },
                        filter = {
                            cwd = true,
                        },
                        layout = { preset = 'telescope', reverse = true },
                    }
                end,
                desc = 'Files',
            },
            {
                '<leader>/',
                function()
                    local grep_search = ''
                    local grep_glob = ''
                    local grep_dirs = {}

                    local function grep()
                        ---@diagnostic disable-next-line: missing-fields
                        Snacks.picker.grep {
                            layout = {
                                preset = 'telescope',
                                reverse = true,
                            },
                            hidden = true,
                            search = grep_search,
                            glob = grep_glob,
                            dirs = grep_dirs,
                            win = {
                                input = {
                                    keys = {
                                        ['<c-e>'] = {
                                            ---@param self snacks.win
                                            ---@diagnostic disable-next-line: assign-type-mismatch
                                            function(self)
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
                                                    grep_glob = input
                                                    grep_search = self:text()
                                                    Snacks.picker.grep() -- close current picker
                                                    grep() -- launch new picker with values
                                                end)
                                            end,
                                            mode = { 'i', 'n' },
                                            desc = 'Filter grep extension',
                                        },
                                        ['<c-d>'] = {
                                            ---@param self snacks.win
                                            ---@diagnostic disable-next-line: assign-type-mismatch
                                            function(self)
                                                grep_search = self:text()
                                                self:close()

                                                local finder =
                                                    require 'conf.snacks.finder'
                                                vim.schedule(function()
                                                    Snacks.picker.files {
                                                        finder = vim.uv.fs_stat '.git'
                                                                and finder.git_dirs
                                                            or finder.fd_dirs,
                                                        -- source = 'Grep folders',
                                                        format = 'filename',
                                                        supports_live = false,
                                                        layout = {
                                                            preset = 'telescope',
                                                            reverse = true,
                                                            preview = false,
                                                        },
                                                        actions = {
                                                            confirm = function(
                                                                picker,
                                                                item
                                                            )
                                                                vim.schedule(
                                                                    function()
                                                                        picker.input.win:action 'close'
                                                                    end
                                                                )

                                                                table.insert(
                                                                    grep_dirs,
                                                                    item.file
                                                                )

                                                                vim.schedule(
                                                                    function()
                                                                        grep()
                                                                    end
                                                                )
                                                            end,
                                                        },
                                                    }
                                                end)
                                            end,
                                            mode = { 'i', 'n' },
                                            desc = 'Filter grep directory',
                                        },
                                    },
                                },
                            },
                        }
                    end

                    grep()
                end,
                desc = 'Grep',
            },
            {
                '<C-s>',
                function()
                    local cursor = vim.api.nvim_win_get_cursor(0)
                    local picker = Snacks.picker.lsp_symbols {
                        layout = {
                            preset = 'dropdown',
                            preview = 'main',
                        },
                    }

                    ---source: dropbar.nvim
                    ---Check if cursor is in range
                    ---@param cursor integer[] cursor position (line, character); (1, 0)-based
                    ---@param range lsp_range_t 0-based range
                    ---@return boolean
                    local function cursor_in_range(cursor, range)
                        local cursor0 = { cursor[1] - 1, cursor[2] }
                        return (
                            cursor0[1] > range.start.line
                            or (
                                cursor0[1] == range.start.line
                                and cursor0[2] >= range.start.character
                            )
                        )
                            and (
                                cursor0[1] < range['end'].line
                                or (
                                    cursor0[1] == range['end'].line
                                    and cursor0[2] <= range['end'].character
                                )
                            )
                    end

                    picker.matcher.task:on('done', function()
                        vim.schedule(function()
                            if picker.list:count() == 0 then
                                return
                            end

                            for _, symbol in ipairs(picker:items()) do
                                if cursor_in_range(cursor, symbol.range) then
                                    picker.list.cursor = symbol.idx
                                end
                            end
                        end)
                    end)

                    --[[ -- alternative: name-based matching using dropbar context
                    local buf = vim.api.nvim_get_current_buf()
                    local win = vim.api.nvim_get_current_win()
                    local symbol = require('dropbar.sources.lsp').get_symbols(
                        buf,
                        win,
                        cursor
                    )
                    vim.print(symbol)
                    picker:find {
                        on_done = function()
                            local current_symbol_context = symbol[1].name
                            for _, symbol in ipairs(picker:items()) do
                                if symbol.name == current_symbol_context then
                                    picker.list.cursor = symbol.idx
                                end
                            end
                        end,
                    } ]]
                end,
                desc = 'LSP symbols',
            },
            {
                '<leader>s',
                function()
                    Snacks.picker.lsp_workspace_symbols {
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
                    Snacks.picker.git_status()
                end,
                desc = 'Git status',
            },
            {
                ',h',
                function()
                    ---@diagnostic disable-next-line: missing-fields
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
                '<Esc>',
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
                '<leader>hl',
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
                desc = 'Yank permlink for Git remote',
            },
        },
        ---@type snacks.Config
        opts = {
            bigfile = { enabled = true },
            gitbrowse = {},
            indent = {
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
                    filter = function(buf)
                        return vim.g.snacks_indent ~= false
                            and vim.b[buf].snacks_indent ~= false
                            and vim.bo[buf].buftype == ''
                            and not vim.tbl_contains({
                                'markdown',
                                'gitcommit',
                            }, vim.bo[buf].filetype)
                    end,
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
            image = { enabled = true },
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
                            ['<Esc>'] = { 'close', mode = { 'i', 'n' } },
                        },
                    },
                    preview = {
                        minimal = true,
                        wo = {
                            relativenumber = false,
                            number = false,
                        },
                    },
                },
                icons = {
                    kinds = {
                        Array = '󰅪',
                        Boolean = '◩',
                        Class = '󰙅',
                        Color = '󰏘',
                        Control = '',
                        Collapsed = '',
                        Constant = '󰏿',
                        Constructor = '',
                        Copilot = '',
                        Enum = '',
                        EnumMember = '',
                        Event = '',
                        Field = '󰜢',
                        File = '󰈙',
                        Folder = '󰉋',
                        Function = '󰊕',
                        Interface = '󰕘',
                        Key = '󰌋',
                        Keyword = '󰌋',
                        Method = '',
                        Module = '',
                        Namespace = '󰌗',
                        Null = '󰢤',
                        Number = '󰎠',
                        Object = '',
                        Operator = '󰆕',
                        Package = '󰆦',
                        Property = '',
                        Reference = '󰋺',
                        Snippet = '󰩫',
                        String = '󰉾',
                        Struct = '󱡠',
                        Text = '',
                        TypeParameter = '󰊄',
                        Unit = '',
                        Unknown = '',
                        Value = '󰦨',
                        Variable = '󰀫',
                    },
                },
            },
            terminal = {
                keys = { ['\\'] = 'hide' },
            },
            words = { enabled = true },
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
    { 'ellisonleao/glow.nvim', cmd = 'Glow' },
    {
        'jamestthompson3/nvim-remote-containers',
        cmd = { 'AttachToContainer', 'BuildImage', 'StartImage' },
        enabled = false,
    },
    { 'mrjones2014/op.nvim', build = 'make install', lazy = true },
}
