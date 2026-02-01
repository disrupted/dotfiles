---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'johmsalas/text-case.nvim',
        cmd = 'Subs',
        main = 'textcase',
        init = function()
            require('which-key').add {
                { 'zc', mode = { 'n', 'v' }, group = 'Coerce', icon = '󰬴' },
                { 'zx', group = 'Coerce (operator)', icon = '󰬴' },
            }

            local ignored_nodes = { 'string', 'comment' }
            local function is_inside_ignored_node()
                local node = vim.treesitter.get_node()
                while node do
                    if vim.tbl_contains(ignored_nodes, node:type()) then
                        return true
                    end
                    node = node:parent()
                end
                return false
            end

            local function textcase_map(char, operation, desc)
                vim.keymap.set('n', 'zc' .. char, function()
                    local clients_supporting_rename = vim.lsp.get_clients {
                        bufnr = 0,
                        method = 'textDocument/rename',
                    }
                    if
                        vim.tbl_isempty(clients_supporting_rename)
                        or is_inside_ignored_node()
                    then
                        require('textcase').current_word(operation)
                    else
                        require('textcase').lsp_rename(operation)
                    end
                end, { desc = 'to ' .. desc })
                vim.keymap.set('n', 'zx' .. char, function()
                    require('textcase').operator(operation)
                end, { desc = 'to ' .. desc })
                vim.keymap.set('v', 'zc' .. char, function()
                    require('textcase').visual(operation)
                end, { desc = 'to ' .. desc })
            end

            textcase_map('s', 'to_snake_case', 'snake_case')
            textcase_map('d', 'to_dash_case', 'dash-case')
            textcase_map('c', 'to_camel_case', 'camelCase')
            textcase_map('p', 'to_pascal_case', 'PascalCase')
            textcase_map('v', 'to_constant_case', 'CONSTANT_CASE') -- environment variable
            textcase_map('t', 'to_title_case', 'Title Case')
            textcase_map('r', 'to_phrase_case', 'Regular phrase case')
            textcase_map('.', 'to_dot_case', 'dot.case')
        end,
        opts = {
            default_keymappings_enabled = false,
            -- substitude_command_name = 'S', -- do not overwrite vim-abolish until feature parity
        },
    },
    {
        'kylechui/nvim-surround',
        event = { 'BufWinEnter', 'BufNewFile' },
        ---@module 'nvim-surround.config'
        ---@type user_options
        opts = { keymaps = { visual = 's' } },
    },
    {
        'tar80/matchwith.nvim',
        enabled = false, -- FIXME: plugin bugs cause some errors
        event = { 'BufWinEnter', 'BufNewFile' },
        ---@module 'matchwith.config'
        ---@type Options
        ---@diagnostic disable-next-line: missing-fields
        opts = {
            jump_key = '%',
            ignore_filetypes = {},
        },
    },
    {
        'numToStr/Comment.nvim',
        keys = {
            { 'gc', mode = { 'n', 'v' }, desc = 'Toggle linewise comment' },
            { 'gb', mode = { 'n', 'v' }, desc = 'Toggle blockwise comment' },
        },
        opts = function()
            return {
                ignore = '^$', -- ignore empty lines
                pre_hook = require(
                    'ts_context_commentstring.integrations.comment_nvim'
                ).create_pre_hook(),
            }
        end,
        dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' },
        config = function(_, opts)
            require('Comment').setup(opts)
            local ft = require 'Comment.ft'
            ft.helm = { '{{/* %s */}}', '{{/* %s */}}' }
        end,
    },
    {
        'abecodes/tabout.nvim',
        event = 'InsertEnter',
        ---@module 'tabout.config'
        ---@type TaboutOptions
        ---@diagnostic disable-next-line: missing-fields
        opts = {
            completion = false,
            tabouts = {
                { open = '\'', close = '\'' },
                { open = '"', close = '"' },
                { open = '`', close = '`' },
                { open = '(', close = ')' },
                { open = '[', close = ']' },
                { open = '{', close = '}' },
                { open = '#', close = ']' }, -- Rust macros
                { open = '<', close = '>' }, -- Java type annotation
            },
            ignore_beginning = true,
        },
    },
    {
        'altermo/ultimate-autopair.nvim',
        event = {
            'InsertEnter',
            -- 'CmdlineEnter'
        },
        branch = 'v0.6',
        opts = {
            cmap = false,
            extensions = {
                cond = {
                    -- disable in comments
                    -- https://github.com/altermo/ultimate-autopair.nvim/blob/6fd0d6aa976a97dd6f1bed4d46be1b437613a52f/Q%26A.md?plain=1#L26
                    cond = {
                        function(fn)
                            return not fn.in_node 'comment'
                        end,
                    },
                },
                -- get fly mode working on strings:
                -- https://github.com/altermo/ultimate-autopair.nvim/issues/33
                fly = {
                    nofilter = true,
                },
            },
            config_internal_pairs = {
                { '"', '"', fly = true },
                { '\'', '\'', fly = true },
            },
            space2 = { enable = true },
            tabout = {
                enable = false,
                map = '<Tab>',
                hopout = true,
                do_nothing_if_fail = false,
            },
            { '\\(', '\\)' },
            { '\\[', '\\]' },
            { '\\{', '\\}' },
            {
                '<',
                '>',
                disable_start = true,
                disable_end = true,
            },
        },
        config = function(_, opts)
            local aupair = require 'ultimate-autopair'
            aupair.init {
                aupair.extend_default(opts),
            }
        end,
    },
    {
        'monaqa/dial.nvim',
        init = function()
            require('which-key').add {
                mode = { 'n', 'v' },
                { '<Leader>j', desc = 'Increment value', icon = '' },
                { '<Leader>k', desc = 'Decrement value', icon = '' },
            }
        end,
        keys = {
            {
                '<Leader>j',
                function()
                    return require('dial.map').inc_normal()
                end,
                expr = true,
            },
            {
                '<Leader>k',
                function()
                    return require('dial.map').dec_normal()
                end,
                expr = true,
            },
            {
                '<Leader>j',
                function()
                    return require('dial.map').inc_visual()
                end,
                mode = 'v',
                expr = true,
            },
            {
                '<Leader>k',
                function()
                    return require('dial.map').dec_visual()
                end,
                mode = 'v',
                expr = true,
            },
        },
        config = function()
            local augend = require 'dial.augend'
            require('dial.config').augends:register_group {
                default = {
                    augend.integer.alias.decimal,
                    augend.constant.alias.bool,
                    augend.constant.new {
                        elements = { 'True', 'False' },
                        word = true,
                        cyclic = true,
                    },
                    augend.semver.alias.semver,
                    augend.date.alias['%Y/%m/%d'], -- date (2022/02/20, etc.)
                    augend.constant.new {
                        elements = { 'and', 'or' },
                        word = true,
                        cyclic = true,
                    },
                    augend.constant.new {
                        elements = { '&&', '||' },
                        word = false,
                        cyclic = true,
                    },
                },
            }
        end,
    },
    {
        'ThePrimeagen/refactoring.nvim',
        init = function()
            require('which-key').add {
                { '<Leader>r', mode = 'v', group = 'Refactor' },
            }
        end,
        keys = {
            {
                '<Leader>rr',
                mode = 'v',
                function()
                    require('refactoring').select_refactor {
                        show_success_message = true,
                    }
                end,
                desc = 'Select refactor',
            },
            {
                '<Leader>re',
                mode = 'v',
                function()
                    require('refactoring').refactor 'Extract Function'
                end,
                desc = 'Extract function',
            },
        },
        opts = {},
    },
    {
        'nvim-neotest/neotest',
        init = function()
            require('which-key').add {
                { '<Leader>t', group = 'Test', icon = '' },
            }
        end,
        keys = {
            {
                '<Leader>tf',
                function()
                    _ = require('conf.neotest.adapters')[vim.bo.filetype]
                    require('neotest').run.run { suite = false }
                end,
                desc = 'Nearest function',
            },
            {
                '<Leader>tb',
                function()
                    _ = require('conf.neotest.adapters')[vim.bo.filetype]
                    require('neotest').run.run {
                        vim.api.nvim_buf_get_name(0),
                        suite = false,
                    }
                end,
                desc = 'Entire file/buffer',
            },
            {
                '<Leader>ta',
                function()
                    _ = require('conf.neotest.adapters')[vim.bo.filetype]
                    for _, adapter_id in
                        ipairs(require('neotest').state.adapter_ids())
                    do
                        require('neotest').run.run {
                            suite = true,
                            adapter_id = adapter_id,
                        }
                    end
                end,
                desc = 'Entire project',
            },
            {
                '<Leader>td',
                function()
                    _ = require('conf.neotest.adapters')[vim.bo.filetype]
                    _ = require('conf.dap.adapters')[vim.bo.filetype]
                    require('neotest').run.run {
                        strategy = 'dap',
                        suite = false,
                    }
                end,
                desc = 'Debug nearest function',
            },
            {
                '<Leader>tl',
                function()
                    require('neotest').run.run_last()
                end,
                desc = 'Re-run last',
            },
            {
                '<Leader>to',
                function()
                    -- require('neotest').output.open { last_run = true }
                    require('overseer').open()
                end,
                desc = 'Open output of last run',
            },
            {
                '<Leader>ts',
                function()
                    if
                        not package.loaded.neotest
                        or vim.tbl_isempty(require('neotest.config').adapters)
                    then
                        local filetypes =
                            require('conf.workspace').project_filetypes()
                        for _, filetype in ipairs(filetypes) do
                            _ = require('conf.neotest.adapters')[filetype]
                        end
                    end

                    if vim.bo.filetype == 'neotest-summary' then
                        require('neotest').summary.close()
                        return
                    end
                    require('neotest').summary.open()

                    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                        local buf = vim.api.nvim_win_get_buf(win)
                        if vim.bo[buf].filetype == 'neotest-summary' then
                            vim.api.nvim_set_current_win(win)
                            vim.wo[win].wrap = false
                            vim.wo[win].fillchars = 'eob: '
                            vim.keymap.set('n', 'q', '<C-w>q', {
                                buffer = buf,
                                silent = true,
                                desc = 'Close',
                            })
                            return
                        end
                    end
                end,
                desc = 'Toggle summary',
            },
            {
                '<Leader>tq',
                function()
                    require('neotest').run.stop()
                end,
                desc = 'Abort test run',
            },
            {
                ']t',
                function()
                    require('neotest').jump.next { status = 'failed' }
                end,
                desc = 'Next failed test',
            },
            {
                '[t',
                function()
                    require('neotest').jump.prev { status = 'failed' }
                end,
                desc = 'Prev failed test',
            },
        },
        dependencies = { { 'nvim-neotest/nvim-nio', lazy = true } },
        ---@module 'neotest.config'
        ---@type neotest.Config
        ---@diagnostic disable-next-line: missing-fields
        opts = {
            ---@diagnostic disable-next-line: missing-fields
            floating = { border = 'single' },
            adapters = {},
            consumers = {
                notify = function(client)
                    client.listeners.results = function(_, results, partial)
                        if partial then
                            return
                        end
                        local error = vim.iter(vim.tbl_values(results))
                            :any(function(result)
                                return not vim.tbl_isempty(result.errors)
                            end)
                        require('neotest.lib').notify(
                            'Tests completed',
                            error and vim.log.levels.WARN or vim.log.levels.INFO
                        )
                    end
                    return {}
                end,
                autocmd_run = function(client)
                    client.listeners.run = function()
                        vim.schedule(function()
                            vim.api.nvim_exec_autocmds('User', {
                                pattern = 'NeotestRun',
                                modeline = false,
                            })
                        end)
                    end
                    return {}
                end,
                autocmd_results = function(client)
                    client.listeners.results = function(
                        adapter_id,
                        results,
                        partial
                    )
                        vim.schedule(function()
                            vim.api.nvim_exec_autocmds('User', {
                                pattern = 'NeotestResult',
                                modeline = false,
                                data = {
                                    adapter_id = adapter_id,
                                    results = results,
                                    partial = partial,
                                },
                            })
                        end)
                    end
                    return {}
                end,
            },
            quickfix = {
                enabled = false,
                open = true,
            },
            summary = {
                mappings = {
                    expand = { '<right>', '<left>', '<2-LeftMouse>' },
                    expand_all = 'e',
                    jumpto = '<CR>',
                },
            },
            icons = vim.tbl_extend('force', require('conf.icons').test, {
                running_animated = {
                    '⠋',
                    '⠙',
                    '⠹',
                    '⠸',
                    '⠼',
                    '⠴',
                    '⠦',
                    '⠧',
                    '⠇',
                    '⠏',
                },
            }),
        },
        ---@module 'neotest.config'
        ---@param opts neotest.Config
        config = function(_, opts)
            opts = vim.tbl_deep_extend('force', opts, {
                consumers = {
                    overseer = require 'neotest.consumers.overseer',
                },
            }) --[[@as neotest.Config]]
            require('neotest').setup(opts)
        end,
    },
    {
        'nvim-neotest/neotest-python',
        lazy = true,
        keys = {
            {
                '<Leader>tu',
                function()
                    require('neotest').run.run {
                        suite = false,
                        extra_args = { '--snapshot-update' },
                    }
                end,
                ft = 'python',
                desc = 'Update snapshot for nearest function',
            },
            {
                '<Leader>tU',
                function()
                    require('neotest').run.run {
                        vim.api.nvim_buf_get_name(0),
                        suite = false,
                        extra_args = { '--snapshot-update' },
                    }
                end,
                ft = 'python',
                desc = 'Update snapshot for entire file/buffer',
            },
        },
        dependencies = { 'nvim-neotest/neotest' },
        init = function()
            require('conf.neotest.adapters').python = 'neotest-python'
        end,
        ---@module 'neotest-python.adapter'
        ---@type neotest-python._AdapterConfig
        ---@diagnostic disable-next-line: missing-fields
        opts = {
            dap = { justMyCode = true },
            runner = 'pytest',
            args = {
                '-s', -- don't capture console output
                '--log-level',
                'DEBUG',
                '-vv',
                -- '--color=no',
            },
            -- pytest_discover_instances = true, -- experimental, support parametrized test cases
        },
        config = function(_, opts)
            local adapter = require 'neotest-python'(opts)
            local adapters = require('neotest.config').adapters
            table.insert(adapters, adapter)
        end,
    },
    {
        'haydenmeade/neotest-jest',
        lazy = true,
        dependencies = { 'nvim-neotest/neotest' },
        init = function()
            for _, filetype in ipairs {
                'javascript',
                'typescript',
                'javascriptreact',
                'typescriptreact',
            } do
                require('conf.neotest.adapters')[filetype] = 'neotest-jest'
            end
        end,
        opts = {
            jestCommand = 'npm test --',
            env = { CI = true },
            cwd = function()
                return vim.uv.cwd()
            end,
        },
        config = function(_, opts)
            local adapter = require 'neotest-jest'(opts)
            local adapters = require('neotest.config').adapters
            table.insert(adapters, adapter)
        end,
    },
    {
        'andythigpen/nvim-coverage',
        cmd = {
            'Coverage',
            'CoverageLoad',
            'CoverageLoadLcov',
            'CoverageShow',
            'CoverageHide',
            'CoverageToggle',
            'CoverageClear',
            'CoverageSummary',
        },
        opts = {
            commands = true,
            -- TODO: link existing hl groups
            highlights = {
                covered = { fg = '#C3E88D' },
                uncovered = { fg = '#F07178' },
            },
            signs = {
                covered = { hl = 'CoverageCovered', text = '▎' },
                uncovered = { hl = 'CoverageUncovered', text = '▎' },
            },
            summary = {
                min_coverage = 80.0,
            },
        },
    },
    {
        'danymat/neogen',
        cmd = 'Neogen',
        init = function()
            require('which-key').add {
                { '<Leader>D', group = 'Generate docs', icon = '󰦨' },
            }
        end,
        keys = {
            {
                '<Leader>Df',
                function()
                    require('neogen').generate {}
                end,
                desc = 'Function',
            },
            {
                '<Leader>DC',
                function()
                    require('neogen').generate { type = 'class' }
                end,
                desc = 'Class',
            },
        },
        opts = {
            snippet_engine = 'luasnip',
            languages = {
                python = {
                    template = {
                        annotation_convention = 'reST',
                    },
                },
                lua = {
                    template = {
                        annotation_convention = 'emmylua',
                    },
                },
            },
        },
    },
    {
        'michaelb/sniprun',
        build = 'sh install.sh',
        cmd = { 'SnipRun', 'SnipInfo' },
        opts = {
            selected_interpreters = { 'Lua_nvim', 'Python3_fifo' },
        },
    },
    { 'hkupty/iron.nvim', enabled = false },
    {
        'stevearc/overseer.nvim',
        cmd = {
            'OverseerOpen',
            'OverseerToggle',
            'OverseerRun',
        },
        keys = {
            { '\\', '<cmd>OverseerToggle<cr>', desc = 'Toggle Overseer' },
            { '<M-\\>', '<cmd>OverseerRun<cr>', desc = 'Overseer run' },
        },
        ---@module 'overseer.config'
        ---@type overseer.Config
        opts = {
            templates = {
                'builtin',
                'python.poetry',
                'python.uv',
            },
            keymaps = {
                ['<C-u>'] = 'keymap.scroll_output_up',
                ['<C-d>'] = 'keymap.scroll_output_down',
            },
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
        },
        config = function(_, opts)
            local overseer = require 'overseer'
            overseer.setup(opts)

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

            vim.api.nvim_create_autocmd('FileType', {
                group = vim.api.nvim_create_augroup(
                    'OverseerListCursor',
                    { clear = true }
                ),
                pattern = 'OverseerList',
                callback = function(args)
                    vim.api.nvim_create_autocmd('WinEnter', {
                        buffer = args.buf,
                        callback = require('conf.ui').cursor.hide,
                    })
                    vim.api.nvim_create_autocmd('WinLeave', {
                        buffer = args.buf,
                        callback = require('conf.ui').cursor.show,
                    })
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if vim.api.nvim_win_get_buf(win) == args.buf then
                            vim.wo[win].fillchars = 'eob: '
                            vim.wo[win].winhighlight = 'CursorLine:Visual'
                            return
                        end
                    end
                end,
            })

            local function toggle_runner(window)
                if vim.bo.buftype == 'terminal' then
                    vim.cmd 'close'
                    return
                end

                -- check for Overseer window
                local task_list = require 'overseer.task_list'
                local tasks = overseer.list_tasks {
                    status = {
                        overseer.STATUS.RUNNING,
                        overseer.STATUS.SUCCESS,
                        overseer.STATUS.FAILURE,
                        overseer.STATUS.CANCELED,
                    },
                    sort = task_list.sort_finished_recently,
                }

                if vim.tbl_isempty(tasks) then
                    Snacks.notify.warn('No tasks found', { title = 'Overseer' })
                else
                    local most_recent = tasks[1]
                    overseer.run_action(most_recent, 'open ' .. window)
                end
            end

            vim.keymap.set('n', '|', function()
                toggle_runner 'float'
            end, { desc = 'Overseer: open task in floating window' })
        end,
    },
    {
        'Zeioth/compiler.nvim',
        cmd = { 'CompilerOpen', 'CompilerToggleResults', 'CompilerRedo' },
        dependencies = { 'stevearc/overseer.nvim' },
        opts = {},
    },
    {
        'folke/todo-comments.nvim',
        cmd = { 'TodoQuickFix', 'TodoTrouble' },
        keys = {
            {
                '[c',
                function()
                    require('todo-comments').jump_prev()
                end,
                desc = 'Prev todo comment',
            },
            {
                ']c',
                function()
                    require('todo-comments').jump_next()
                end,
                desc = 'Next todo comment',
            },
        },
        init = function()
            vim.api.nvim_create_user_command('Todo', 'TodoTrouble', {})
            vim.api.nvim_create_user_command(
                'TodoBuffer',
                'TodoTrouble filter.buf=0',
                {}
            )
        end,
        opts = {
            search = { pattern = [[\b(KEYWORDS)(\([^\)]*\))?:]] },
            highlight = { pattern = [[.*<((KEYWORDS)%(\(.{-1,}\))?):]] },
        },
        config = function(_, opts)
            -- HACK: no option to disable highlighting globally
            ---@diagnostic disable-next-line: duplicate-set-field
            require('todo-comments.highlight').start = function() end
            require('todo-comments').setup(opts)
        end,
    },
    {
        'MagicDuck/grug-far.nvim',
        cmd = 'GrugFar',
        keys = {
            -- {
            --     '<Leader>R',
            --     function()
            --         require('grug-far').grug_far()
            --     end,
            --     desc = 'Grug-Far',
            -- },
            -- {
            --     '<Leader>Rf',
            --     function()
            --         require('grug-far').grug_far {
            --             prefills = { flags = vim.fn.expand '%' },
            --         }
            --     end,
            --     desc = 'Grug-Far: current file',
            -- },
            -- {
            --     '<Leader>Rv',
            --     function()
            --         require('grug-far').with_visual_selection {
            --             prefills = { flags = vim.fn.expand '%' },
            --         }
            --     end,
            --     desc = 'Grug-Far: visual selection',
            -- },
            -- {
            --     '<Leader>Rw',
            --     function()
            --         require('grug-far').grug_far {
            --             prefills = { search = vim.fn.expand '<cword>' },
            --         }
            --     end,
            --     desc = 'Grug-Far: current word',
            -- },
        },
        opts = {},
    },
}
