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
                        finder = 'smart',
                        finders = {
                            'buffers',
                            'recent',
                            vim.uv.fs_stat '.git' and 'git_files' or 'files',
                        },
                        format = 'file',
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
                    local search = ''
                    local glob = ''
                    local dirs = {}

                    local function grep()
                        ---@diagnostic disable-next-line: missing-fields
                        Snacks.picker.grep {
                            layout = {
                                preset = 'telescope',
                                reverse = true,
                            },
                            hidden = true,
                            search = search,
                            glob = glob,
                            dirs = dirs,
                            win = {
                                input = {
                                    keys = {
                                        ['<c-e>'] = {
                                            ---@param self snacks.win
                                            ---@diagnostic disable-next-line: assign-type-mismatch
                                            function(self)
                                                vim.ui.input(
                                                    { prompt = '*.' },
                                                    function(input)
                                                        if
                                                            not input
                                                            or input == ''
                                                        then
                                                            return
                                                        end
                                                        glob = '*.' .. input
                                                        search = self:text()
                                                        self:close()
                                                        grep()
                                                    end
                                                )
                                            end,
                                            mode = { 'i', 'n' },
                                        },
                                        ['<c-f>'] = {
                                            ---@param self snacks.win
                                            ---@diagnostic disable-next-line: assign-type-mismatch
                                            function(self)
                                                search = self:text()
                                                self:execute 'close'

                                                local folders = {}

                                                if vim.uv.fs_stat '.git' then
                                                    local cmd = vim.system({
                                                        'git',
                                                        'ls-tree',
                                                        '-rtd',
                                                        'HEAD',
                                                        '--name-only',
                                                    }, {
                                                        text = true,
                                                    }):wait()
                                                    folders = vim.split(
                                                        cmd.stdout,
                                                        '\n'
                                                    )
                                                else
                                                    folders = vim.fs.find(
                                                        function()
                                                            return true
                                                        end,
                                                        {
                                                            limit = 1000,
                                                            type = 'directory',
                                                        }
                                                    )
                                                end

                                                ---@type snacks.picker.finder.Item[]
                                                local finder_items = {}
                                                for idx, item in ipairs(folders) do
                                                    table.insert(finder_items, {
                                                        file = item,
                                                        text = item,
                                                        dir = true,
                                                        idx = idx,
                                                    })
                                                end

                                                vim.schedule(function()
                                                    Snacks.picker.pick {
                                                        source = 'Grep folders',
                                                        items = finder_items,
                                                        format = 'filename',
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
                                                                    dirs,
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
                '<Tab>',
                function()
                    Snacks.notifier.show_history()
                end,
                desc = 'Show notification history',
            },
        },
        ---@type snacks.Config
        opts = {
            bigfile = { enabled = true },
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
}
