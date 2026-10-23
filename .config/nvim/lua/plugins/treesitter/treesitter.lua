---@type LazeSpec
return {
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
        local treesitter = require('nvim-treesitter')
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
                elseif vim.list_contains(treesitter.get_available(), lang) then
                    -- HACK: try starting it anyways, some external parsers (e.g. ghostty) aren't correctly detected as installed
                    local ok = pcall(vim.treesitter.start, args.buf, lang)
                    if not ok then
                        if vim.b[args.buf].ts_available_notified_lang ~= lang then
                            Snacks.notify(
                                string.format(
                                    'Treesitter parser available for %s',
                                    lang
                                )
                            )
                            vim.b[args.buf].ts_available_notified_lang = lang
                        end
                    end
                end
            end,
            desc = 'Enable Treesitter for installed languages',
        })
    end,
}
