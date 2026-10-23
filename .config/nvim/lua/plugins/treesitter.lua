---@type LazeSpec[]
return {
    {
        'nvim-treesitter/nvim-treesitter',
        branch = 'main',
        main = 'nvim-treesitter',
        module = 'nvim-treesitter',
        event = { 'BufReadPost', 'BufNewFile', 'FileType' },
        lazy = vim.fn.argc(-1) == 0, -- load Treesitter early when opening a file from the cmdline
        build = ':TSUpdate',
        config = function()
            local opts = {
                ensure_installed = {
                    'angular',
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
                    'ini',
                    'java',
                    'javascript',
                    'jsdoc',
                    'json',
                    'json5',
                    'just',
                    'kdl',
                    'kotlin',
                    'latex',
                    'llvm',
                    'lua',
                    'make',
                    'markdown',
                    'markdown_inline',
                    'nickel',
                    'ninja',
                    'nix',
                    'nu',
                    'pkl',
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
                    'tsx',
                    'typescript',
                    'typst',
                    'vim',
                    'vimdoc',
                    'xml',
                    'yaml',
                    'zsh',
                },
            }
            local treesitter = require 'nvim-treesitter'
            treesitter.install(opts.ensure_installed)

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
                        -- HACK: try starting it anyways, some external parsers (e.g. ghostty) aren't correctly detected as installed
                        local ok = pcall(vim.treesitter.start, args.buf, lang)
                        if not ok then
                            if
                                vim.b[args.buf].ts_available_notified_lang
                                ~= lang
                            then
                                Snacks.notify(
                                    string.format(
                                        'Treesitter parser available for %s',
                                        lang
                                    )
                                )
                                vim.b[args.buf].ts_available_notified_lang =
                                    lang
                            end
                        end
                    end
                end,
                desc = 'Enable Treesitter for installed languages',
            })
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = 'main',
        main = 'nvim-treesitter-textobjects',
        module = 'nvim-treesitter-textobjects',
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
        config = function()
            local opts = {
                select = {
                    selection_modes = {
                        ['@function.outer'] = 'V', -- linewise
                        ['@class.outer'] = 'V', -- linewise
                    },
                },
            }
            require('nvim-treesitter-textobjects').setup(opts)
        end,
    },
    {
        'bezhermoso/tree-sitter-ghostty',
        main = 'tree-sitter-ghostty',
        module = 'tree-sitter-ghostty',
        ft = 'ghostty',
        build = 'make nvim_install',
    },
}
