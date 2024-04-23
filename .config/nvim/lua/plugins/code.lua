return {
    {
        'johmsalas/text-case.nvim',
        lazy = true,
        init = function()
            local function textcase_map(char, operation)
                vim.keymap.set('n', 'za' .. char, function()
                    require('textcase').current_word(operation)
                end)
                local upper = char:upper()
                if upper ~= char then
                    vim.keymap.set('n', 'za' .. upper, function()
                        require('textcase').lsp_rename(operation)
                    end)
                end
                vim.keymap.set('n', 'z' .. char, function()
                    require('textcase').operator(operation)
                end)
                vim.keymap.set('v', 'z' .. char, function()
                    require('textcase').visual(operation)
                end)
            end

            textcase_map('s', 'to_snake_case')
            textcase_map('d', 'to_dash_case')
            textcase_map('c', 'to_camel_case')
            textcase_map('p', 'to_pascal_case')
            textcase_map('v', 'to_constant_case') -- environment variable
            textcase_map('t', 'to_title_case')
            textcase_map('p', 'to_phrase_case')
            textcase_map('.', 'to_dot_case')
        end,
    },
    {
        'kylechui/nvim-surround',
        event = { 'BufWinEnter', 'BufNewFile' },
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
        'windwp/nvim-autopairs',
        event = 'InsertCharPre',
        opts = { check_ts = true },
        config = function(_, opts)
            local npairs = require 'nvim-autopairs'
            npairs.setup(opts)

            local Rule = require 'nvim-autopairs.rule'
            npairs.add_rule(Rule('[', ']'))
            npairs.add_rule(Rule('<', '>'))
            npairs.add_rule(Rule('|', '|', 'rust'))
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
            },
            {
                '<leader>k',
                function()
                    return require('dial.map').dec_normal()
                end,
                expr = true,
            },
            {
                '<leader>j',
                function()
                    return require('dial.map').inc_visual()
                end,
                mode = 'v',
                expr = true,
            },
            {
                '<leader>k',
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
                    require('neotest').run.run()
                end,
                desc = 'test nearest function',
            },
            {
                '<leader>tb',
                function()
                    require('neotest').run.run(vim.api.nvim_buf_get_name(0))
                end,
                desc = 'test entire file/buffer',
            },
            {
                '<leader>tu',
                function()
                    require('neotest').run.run {
                        vim.api.nvim_buf_get_name(0),
                        suite = true,
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
                        ipairs(require('neotest').run.adapters())
                    do
                        require('neotest').run.run {
                            suite = true,
                            adapter = adapter_id,
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
                    require('neotest').run.run { strategy = 'dap', suite = false }
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
                        pytest_discover_instances = true, -- experimental, support parametrized test cases
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
                '<leader>nf',
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
        cmd = { 'OverseerRun', 'OverseerToggle' },
        opts = {
            task_list = {
                bindings = {
                    ['<C-l>'] = false,
                    ['<C-h>'] = false,
                },
            },
        },
    },
    {
        'folke/todo-comments.nvim',
        cmd = { 'TodoQuickFix', 'TodoTrouble', 'TodoTelescope' },
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
