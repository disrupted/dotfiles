return {
    {
        'neovim/nvim-lspconfig',
        event = { 'BufReadPre', 'BufNewFile' },
        init = function()
            require('conf.lsp').setup()
        end,
        config = function()
            require('conf.lsp').config()
        end,
        dependencies = {
            'folke/neodev.nvim',
            'hrsh7th/cmp-nvim-lsp',
        },
    },
    { 'kosayoda/nvim-lightbulb', lazy = true },
    { 'zbirenbaum/neodim', lazy = true },
    {
        'lvimuser/lsp-inlayhints.nvim',
        -- branch = 'anticonceal',
        lazy = true,
    },
    {
        'jose-elias-alvarez/null-ls.nvim',
        event = 'BufReadPre',
        opts = function()
            local null_ls = require 'null-ls'

            -- custom sources
            local h = require 'null-ls.helpers'

            local blackd = {
                name = 'blackd',
                method = null_ls.methods.FORMATTING,
                filetypes = { 'python' },
                generator = h.formatter_factory {
                    command = 'blackd-client',
                    to_stdin = true,
                },
            }

            local isortd = {
                name = 'isortd',
                method = null_ls.methods.FORMATTING,
                filetypes = { 'python' },
                generator = h.formatter_factory {
                    command = 'curl',
                    args = {
                        '-s',
                        '-X',
                        'POST',
                        'localhost:47393',
                        '-H',
                        'XX-SRC: $ROOT',
                        '-H',
                        'XX-PATH: $FILENAME',
                        '--data-binary',
                        '@-',
                    },
                    to_stdin = true,
                },
            }

            local function dprint_config()
                local lsputil = require 'lspconfig.util'
                local path = lsputil.path.join(vim.loop.cwd(), 'dprint.json')
                print(path)
                if lsputil.path.exists(path) then
                    print 'path exists'
                    return path
                end
                print 'path doesnt exist'
                return vim.fn.expand '~/.config/dprint.json'
            end

            local dprint = {
                name = 'dprint',
                method = null_ls.methods.FORMATTING,
                filetypes = {
                    'json',
                    'markdown',
                    'javascript',
                    'javascriptreact',
                    'typescript',
                    'typescriptreact',
                    'toml',
                    'dockerfile',
                    'css',
                },
                generator = h.formatter_factory {
                    command = 'dprint',
                    -- condition = function(utils)
                    --     return utils.root_has_file 'dprint.json'
                    -- end,
                    args = {
                        'fmt',
                        '--config',
                        -- dprint_config(),
                        -- require('lspconfig.util').path.join(
                        --     vim.loop.cwd(),
                        --     'dprint.json'
                        -- ),
                        vim.fn.expand '~/.config/dprint.json',
                        '--stdin',
                        '$FILEEXT',
                    },
                    to_stdin = true,
                },
            }

            local sources = {
                null_ls.builtins.formatting.stylua.with {
                    condition = function(utils)
                        return utils.root_has_file 'stylua.toml'
                    end,
                },
                isortd,
                blackd,
                dprint,
                null_ls.builtins.formatting.prettierd.with {
                    filetypes = {
                        'vue',
                        'svelte',
                        -- 'css',
                        -- 'scss',
                        'less',
                        'html',
                        'yaml',
                        'graphql',
                    },
                    -- condition = function(utils)
                    --     return not utils.root_has_file 'dprint.json'
                    -- end,
                },
                null_ls.builtins.formatting.uncrustify.with {
                    condition = function(utils)
                        return utils.root_has_file 'uncrustify.cfg'
                    end,
                    extra_args = {
                        '-c',
                        require('lspconfig.util').path.join(
                            vim.loop.cwd(),
                            'uncrustify.cfg'
                        ),
                    }, -- for neovim/neovim repo
                },
                null_ls.builtins.formatting.shfmt.with {
                    extra_args = { '-i', '4', '-ci' },
                },
                -- null_ls.builtins.formatting.trim_whitespace,
                -- null_ls.builtins.formatting.trim_newlines,
                null_ls.builtins.diagnostics.shellcheck,
                null_ls.builtins.diagnostics.actionlint.with {
                    -- based on https://github.com/jose-elias-alvarez/null-ls.nvim/pull/804
                    runtime_condition = function()
                        local path = vim.api.nvim_buf_get_name(
                            vim.api.nvim_get_current_buf()
                        )
                        return path:match 'github/workflows/' ~= nil
                    end,
                },
                -- null_ls.builtins.code_actions.refactoring,
                null_ls.builtins.code_actions.gitrebase,
            }

            return {
                sources = sources,
                debug = false,
                -- Fallback to .zshrc as a project root to enable LSP on loose files
                root_dir = function(fname)
                    return require('lspconfig').util.root_pattern(
                        'tsconfig.json',
                        'pyproject.toml',
                        'stylua.toml',
                        'dprint.json'
                    )(fname) or require('lspconfig').util.root_pattern(
                        '.eslintrc.js',
                        '.git'
                    )(fname) or require('lspconfig').util.root_pattern(
                        'package.json',
                        '.git/',
                        '.zshrc'
                    )(fname)
                end,
            }
        end,
    },
    {
        'disrupted/pylance.nvim',
        build = 'bash ./install.sh',
        lazy = true,
    },
    { 'simrat39/rust-tools.nvim', lazy = true },
    {
        'folke/trouble.nvim',
        cmd = 'Trouble',
        keys = {
            {
                '<leader>xx',
                function()
                    require('trouble').toggle()
                end,
            },
            {
                '<leader>xw',
                function()
                    require('trouble').toggle { mode = 'workspace_diagnostics' }
                end,
            },
            {
                '<leader>xb',
                function()
                    require('trouble').toggle { mode = 'document_diagnostics' }
                end,
            },
            {
                '<leader>xq',
                function()
                    require('trouble').toggle { mode = 'quickfix' }
                end,
            },
        },
        opts = {
            fold_open = '', -- ▾
            fold_closed = '', -- ▸
            indent_lines = false,
            padding = false,
            signs = {
                error = '',
                warning = '',
                hint = '',
                information = '',
                other = '', -- 
            },
            action_keys = { jump = { '<cr>' }, toggle_fold = { '<tab>' } },
        },
        config = function(_, opts)
            require('trouble').setup(opts)
            vim.api.nvim_set_hl(0, 'TroubleText', { link = 'CursorLineNr' })
        end,
    },
    {
        'simrat39/symbols-outline.nvim',
        cmd = 'SymbolsOutline',
        keys = { { '|', '<cmd>SymbolsOutline<cr>' } },
        opts = {
            show_guides = false,
            auto_preview = false,
            preview_bg_highlight = 'Normal',
            symbols = {
                File = { icon = '', hl = 'TSURI' },
                Module = { icon = '', hl = 'TSNamespace' },
                Namespace = { icon = '', hl = 'TSNamespace' },
                Package = { icon = '', hl = 'TSNamespace' },
                Class = { icon = 'ﴯ', hl = 'TSType' },
                Method = { icon = '', hl = 'TSMethod' },
                Property = { icon = 'ﰠ', hl = 'TSMethod' },
                Field = { icon = 'ﰠ', hl = 'TSField' },
                Constructor = { icon = '', hl = 'TSConstructor' },
                Enum = { icon = '', hl = 'TSType' },
                Interface = { icon = '', hl = 'TSType' },
                Function = { icon = '', hl = 'TSFunction' },
                Variable = { icon = '', hl = 'TSConstant' },
                Constant = { icon = '', hl = 'TSConstant' },
                String = { icon = '', hl = 'TSString' },
                Number = { icon = '', hl = 'TSNumber' },
                Boolean = { icon = '⊨', hl = 'TSBoolean' },
                Array = { icon = '', hl = 'TSConstant' },
                Object = { icon = '⦿', hl = 'TSType' },
                Key = { icon = '', hl = 'TSType' },
                Null = { icon = 'NULL', hl = 'TSType' },
                EnumMember = { icon = '', hl = 'TSField' },
                Struct = { icon = 'פּ', hl = 'TSType' },
                Event = { icon = '', hl = 'TSType' },
                Operator = { icon = '', hl = 'TSOperator' },
                TypeParameter = { icon = '', hl = 'TSParameter' },
            },
        },
    },
}
