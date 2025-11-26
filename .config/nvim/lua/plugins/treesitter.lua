---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'nvim-treesitter/nvim-treesitter',
        branch = 'main',
        build = ':TSUpdate',
        event = { 'BufReadPost', 'BufNewFile', 'FileType' },
        lazy = vim.fn.argc(-1) == 0, -- load Treesitter early when opening a file from the cmdline
        opts = {
            ensure_installed = {
                'bash',
                'bibtex',
                'c',
                'cmake',
                'comment',
                'css',
                'csv',
                'diff',
                'dockerfile',
                'dot',
                'fennel',
                'git_config',
                'git_rebase',
                'gitattributes',
                'gitcommit',
                'gitignore',
                'go',
                'graphql',
                'gotmpl',
                'helm',
                'html',
                'htmldjango',
                'http',
                'hurl',
                'java',
                'javascript',
                'jsdoc',
                'json',
                'json5',
                'jsonc',
                'just',
                'kotlin',
                'latex',
                'llvm',
                'lua',
                'make',
                'markdown',
                'markdown_inline',
                'ninja',
                'nix',
                'norg',
                'python',
                'pymanifest',
                'query',
                'regex',
                'requirements',
                'rst',
                'ruby',
                'rust',
                'scheme',
                'scss',
                'sql',
                'ssh_config',
                'svelte',
                'swift',
                'terraform',
                'toml',
                'tmux',
                'tsx',
                'typescript',
                'vim',
                'vimdoc',
                'xml',
                'yaml',
                'zsh',
            },
        },
        config = function(_, opts)
            local treesitter = require 'nvim-treesitter'
            treesitter.install(opts.ensure_installed)

            require('which-key').add {
                { '<CR>', desc = 'Increment selection', mode = { 'x', 'n' } },
                { '<BS>', desc = 'Decrement selection', mode = 'x' },
            }

            -- the filetype on the RHS will use the parser and queries on the LHS
            vim.treesitter.language.register('terraform', 'terraform-vars')

            vim.api.nvim_create_autocmd('FileType', {
                group = vim.api.nvim_create_augroup('treesitter.setup', {}),
                callback = function(args)
                    local lang = vim.treesitter.language.get_lang(args.match)
                    if vim.list_contains(treesitter.get_installed(), lang) then
                        vim.treesitter.start(args.buf, lang)
                        -- vim.wo.foldmethod = 'expr'
                        -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                        vim.bo[args.buf].indentexpr =
                            'v:lua.require\'nvim-treesitter\'.indentexpr()'
                    elseif
                        vim.list_contains(treesitter.get_available(), lang)
                    then
                        Snacks.notify(
                            string.format(
                                'Treesitter parser available for %s',
                                lang
                            )
                        )
                    end
                end,
                desc = 'Enable Treesitter for installed languages',
            })
        end,
    },
    {
        'MeanderingProgrammer/treesitter-modules.nvim',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        event = { 'BufReadPost', 'BufNewFile', 'FileType' },
        ---@module 'treesitter-modules'
        ---@type ts.mod.UserConfig
        opts = {
            incremental_selection = {
                enable = true,
                disable = {},
                keymaps = {
                    init_selection = '<CR>', -- maps in normal mode to init the node/scope selection
                    node_incremental = '<CR>', -- increment to the upper named parent
                    -- scope_incremental = '<nop>', -- increment to the upper scope (as defined in locals.scm)
                    node_decremental = '<BS>', -- decrement to the previous node
                },
            },
        },
    },
    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = 'main',
        keys = {
            {
                'af',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@function.outer',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Function outer',
            },
            {
                'if',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@function.inner',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Function inner',
            },
            {
                'aC',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@class.outer',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Class outer',
            },
            {
                'iC',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@class.inner',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Class inner',
            },
            {
                'ap',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@parameter.outer',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Parameter outer',
            },
            {
                'ip',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@parameter.inner',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Parameter inner',
            },
            {
                'ao',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@conditional.outer',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Conditional outer',
            },
            {
                'io',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@conditional.inner',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Conditional inner',
            },
            {
                'ab',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@block.outer',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Block outer',
            },
            {
                'ib',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@block.inner',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Block inner',
            },
            {
                'al',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@loop.outer',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Loop outer',
            },
            {
                'il',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@loop.inner',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Loop inner',
            },
            {
                'as',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@statement.outer',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Statement outer',
            },
            {
                'is',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@statement.inner',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Statement inner',
            },
            {
                'am',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@call.outer',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Call outer',
            },
            {
                'im',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@call.inner',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Call inner',
            },
            {
                'ac',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@comment.outer',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Comment outer',
            },
            {
                'ic',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@comment.inner',
                        'textobjects'
                    )
                end,
                mode = { 'x', 'o' },
                desc = 'Comment inner',
            },
            {
                ']f',
                function()
                    require('nvim-treesitter-textobjects.move').goto_next_start(
                        '@function.outer',
                        'textobjects'
                    )
                end,
                mode = { 'n', 'x', 'o' },
                desc = 'Next function',
            },
            {
                '[f',
                function()
                    require('nvim-treesitter-textobjects.move').goto_previous_start(
                        '@function.outer',
                        'textobjects'
                    )
                end,
                mode = { 'n', 'x', 'o' },
                desc = 'Prev function',
            },
            {
                ']C',
                function()
                    require('nvim-treesitter-textobjects.move').goto_next_start(
                        '@class.outer',
                        'textobjects'
                    )
                end,
                mode = { 'n', 'x', 'o' },
                desc = 'Next class',
            },
            {
                '[C',
                function()
                    require('nvim-treesitter-textobjects.move').goto_previous_start(
                        '@class.outer',
                        'textobjects'
                    )
                end,
                mode = { 'n', 'x', 'o' },
                desc = 'Prev class',
            },
        },
        opts = {
            select = {
                selection_modes = {
                    ['@function.outer'] = 'V', -- linewise
                    ['@class.outer'] = 'V', -- linewise
                },
            },
        },
        config = function(_, opts)
            require('nvim-treesitter-textobjects').setup(opts)
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-refactor',
        enabled = false, -- FIXME: incompatible with nvim-treesitter main branch
        keys = { '<Leader>R' },
        init = function()
            require('which-key').add {
                { '<Leader>R', desc = 'TS: Rename symbol', icon = '󰏫' },
            }
        end,
        opts = {
            highlight_definitions = { enable = false },
            highlight_current_scope = { enable = false },
            smart_rename = {
                enable = true,
                keymaps = {
                    smart_rename = '<Leader>R', -- mapping to rename reference under cursor
                },
            },
            navigation = {
                enable = false, -- disabled in favor of Snacks.words
                keymaps = {
                    goto_definition = 'gnd', -- mapping to go to definition of symbol under cursor
                    list_definitions = 'gnD', -- mapping to list all definitions in current file
                    goto_next_usage = '<C-n>',
                    goto_previous_usage = '<C-p>',
                },
            },
        },
        config = function(_, opts)
            ---@diagnostic disable-next-line: missing-fields
            require('nvim-treesitter.configs').setup { refactor = opts }
        end,
    },
    {
        'bezhermoso/tree-sitter-ghostty',
        ft = 'ghostty',
        build = 'make nvim_install',
    },
    {
        'windwp/nvim-ts-autotag',
        enabled = false,
        event = 'InsertEnter',
        opts = {},
    },
}
