return {
    {
        'johmsalas/text-case.nvim',
        cmd = 'Subs',
        keys = {
            -- FIXME: Snacks.picker
            -- {
            --     'za<space>',
            --     function() end,
            --     mode = { 'n', 'v' },
            --     desc = 'Pick textcase coercion in Telescope',
            -- },
        },
        init = function()
            local function textcase_map(char, operation, desc)
                vim.keymap.set('n', 'za' .. char, function()
                    local clients_supporting_rename = vim.lsp.get_clients {
                        bufnr = 0,
                        method = require('vim.lsp.protocol').Methods.textDocument_rename,
                    }
                    if not vim.tbl_isempty(clients_supporting_rename) then
                        require('textcase').lsp_rename(operation)
                    else
                        require('textcase').current_word(operation)
                    end
                end, { desc = 'Coerce to ' .. desc })
                vim.keymap.set('n', 'z' .. char, function()
                    require('textcase').operator(operation)
                end, { desc = 'Coerce to ' .. desc })
                vim.keymap.set('v', 'z' .. char, function()
                    require('textcase').visual(operation)
                end, { desc = 'Coerce to ' .. desc })
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
        'monkoose/matchparen.nvim',
        event = { 'BufWinEnter', 'BufNewFile' },
        config = true,
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
                enable = true,
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
        keys = {
            {
                '<leader>j',
                function()
                    return require('dial.map').inc_normal()
                end,
                expr = true,
                desc = 'Increment value',
            },
            {
                '<leader>k',
                function()
                    return require('dial.map').dec_normal()
                end,
                expr = true,
                desc = 'Decrement value',
            },
            {
                '<leader>j',
                function()
                    return require('dial.map').inc_visual()
                end,
                mode = 'v',
                expr = true,
                desc = 'Increment value',
            },
            {
                '<leader>k',
                function()
                    return require('dial.map').dec_visual()
                end,
                mode = 'v',
                expr = true,
                desc = 'Decrement value',
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
        keys = {
            {
                '<leader>rr',
                mode = 'v',
                function()
                    require('refactoring').select_refactor {
                        show_success_message = true,
                    }
                end,
            },
            {
                '<leader>re',
                mode = 'v',
                function()
                    require('refactoring').refactor 'Extract Function'
                end,
            },
        },
        config = true,
    },
    {
        'nvim-neotest/neotest',
        keys = {
            {
                '<leader>tf',
                function()
                    require('neotest').run.run {
                        suite = false,
                        env = { REUSE_CONTAINERS = '1' },
                    }
                end,
                desc = 'test nearest function',
            },
            {
                '<leader>tb',
                function()
                    require('neotest').run.run {
                        vim.api.nvim_buf_get_name(0),
                        suite = false,
                        env = { REUSE_CONTAINERS = '1' },
                    }
                end,
                desc = 'test entire file/buffer',
            },
            {
                '<leader>tu',
                function()
                    require('neotest').run.run {
                        suite = false,
                        env = { REUSE_CONTAINERS = '1' },
                        extra_args = { '--snapshot-update' },
                    }
                end,
                ft = 'python',
                desc = 'update snapshot for nearest function',
            },
            {
                '<leader>tU',
                function()
                    require('neotest').run.run {
                        vim.api.nvim_buf_get_name(0),
                        suite = false,
                        env = { REUSE_CONTAINERS = '1' },
                        extra_args = { '--snapshot-update' },
                    }
                end,
                ft = 'python',
                desc = 'update snapshot for entire file/buffer',
            },
            {
                '<leader>ta',
                function()
                    for _, adapter_id in
                        ipairs(require('neotest').state.adapter_ids())
                    do
                        require('neotest').run.run {
                            suite = true,
                            env = { REUSE_CONTAINERS = '1' },
                            adapter_id = adapter_id,
                        }
                    end
                end,
                desc = 'test entire project',
            },
            {
                '<leader>tl',
                function()
                    require('neotest').run.run_last()
                end,
                desc = 're-run the last test',
            },
            {
                '<leader>to',
                function()
                    require('neotest').output.open { last_run = true }
                end,
                desc = 'open output of last test run',
            },
            {
                '<leader>ts',
                function()
                    require('neotest').summary.toggle()
                end,
                desc = 'toggle summary',
            },
            {
                '<leader>td',
                function()
                    require('neotest').run.run {
                        strategy = 'dap',
                        suite = false,
                        env = { REUSE_CONTAINERS = '1' },
                    }
                end,
                desc = 'debug nearest function',
            },
            {
                '<leader>tq',
                function()
                    require('neotest').run.stop()
                end,
                desc = 'abort test run',
            },
        },
        dependencies = {
            { 'nvim-neotest/nvim-nio', lazy = true },
            { 'nvim-neotest/neotest-python', lazy = true },
            { 'rouge8/neotest-rust', lazy = true },
            { 'haydenmeade/neotest-jest', lazy = true },
            {
                'andythigpen/nvim-coverage',
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
        },
        opts = function()
            ---@module 'neotest.config'
            ---@type neotest.CoreConfig
            ---@diagnostic disable-next-line: missing-fields
            return {
                adapters = {
                    require 'neotest-python' {
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
                    require 'neotest-rust',
                    require 'neotest-jest' {
                        jestCommand = 'npm test --',
                        env = { CI = true },
                        cwd = function()
                            return vim.uv.cwd()
                        end,
                    },
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
            }
        end,
    },
    {
        'danymat/neogen',
        cmd = 'Neogen',
        keys = {
            {
                '<leader>fd',
                function()
                    require('neogen').generate {}
                end,
                desc = 'generate docs for function',
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
            },
        },
    },
    {
        'michaelb/sniprun',
        build = 'bash ./install.sh',
        cmd = { 'SnipRun', 'SnipInfo' },
    },
    { 'hkupty/iron.nvim', enabled = false },
    {
        'stevearc/overseer.nvim',
        cmd = {
            'OverseerOpen',
            'OverseerToggle',
            'OverseerRun',
        },
        ---@module 'overseer.config'
        ---@type overseer.Config
        opts = {
            templates = {
                'builtin',
                'python.poetry',
                'python.uv',
            },
            task_list = {
                bindings = {
                    ['<C-j>'] = false,
                    ['<C-k>'] = false,
                    ['<C-h>'] = false,
                    ['<C-l>'] = false,
                    ['<C-u>'] = 'ScrollOutputUp',
                    ['<C-d>'] = 'ScrollOutputDown',
                },
                direction = 'bottom',
                min_height = 25,
                max_height = 25,
                default_detail = 1,
            },
        },
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
                ']t',
                function()
                    require('todo-comments').jump_next()
                end,
                desc = 'jump to next todo',
            },
            {
                '[t',
                function()
                    require('todo-comments').jump_prev()
                end,
                desc = 'jump to previous todo',
            },
        },
        init = function()
            vim.api.nvim_create_user_command('Todo', 'TodoTrouble', {})
        end,
        opts = {
            search = {
                pattern = [[\b(KEYWORDS)\b]], -- match without the extra colon. You'll likely get false positives
            },
        },
        config = true,
    },
}
