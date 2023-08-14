return {
    { 'filNaj/tree-setter', enabled = true },
    {
        'nvim-treesitter/nvim-treesitter',
        event = { 'BufRead', 'BufNewFile' },
        dependencies = {
            'nvim-treesitter/nvim-treesitter-refactor',
            'nvim-treesitter/nvim-treesitter-textobjects',
        },
        build = ':TSUpdate',
        config = function()
            require('nvim-treesitter.configs').setup {
                ensure_installed = {
                    'bash',
                    'bibtex',
                    'c',
                    'cmake',
                    -- 'comment',
                    'css',
                    'diff',
                    'dockerfile',
                    'dot',
                    'fennel',
                    'git_rebase',
                    'gitignore',
                    'go',
                    'graphql',
                    'vimdoc',
                    'html',
                    'http',
                    'java',
                    'javascript',
                    'jsdoc',
                    'json',
                    'json5',
                    'jsonc',
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
                    'query',
                    'regex',
                    'rst',
                    'ruby',
                    'rust',
                    'scheme',
                    'scss',
                    'terraform',
                    'toml',
                    'tsx',
                    'typescript',
                    'vim',
                    'yaml',
                },
                highlight = { enable = true },
                -- indent = { enable = true, disable = { 'python', 'yaml' } },
                indent = { enable = true },
                incremental_selection = {
                    enable = true,
                    disable = {},
                    keymaps = {
                        init_selection = '<CR>', -- maps in normal mode to init the node/scope selection
                        node_incremental = '<CR>', -- increment to the upper named parent
                        scope_incremental = '<nop>', -- increment to the upper scope (as defined in locals.scm)
                        node_decremental = '<BS>', -- decrement to the previous node
                    },
                },
                refactor = {
                    highlight_definitions = { enable = true },
                    highlight_current_scope = { enable = false },
                    smart_rename = {
                        enable = true,
                        keymaps = {
                            smart_rename = 'grr', -- mapping to rename reference under cursor
                        },
                    },
                    navigation = {
                        enable = true,
                        keymaps = {
                            goto_definition = 'gnd', -- mapping to go to definition of symbol under cursor
                            list_definitions = 'gnD', -- mapping to list all definitions in current file
                            goto_next_usage = '<leader>n',
                            goto_previous_usage = '<leader>N',
                        },
                    },
                },
                textobjects = { -- syntax-aware textobjects
                    select = {
                        enable = true,
                        disable = {},
                        keymaps = {
                            -- You can use the capture groups defined in textobjects.scm
                            ['af'] = '@function.outer',
                            ['if'] = '@function.inner',
                            ['aC'] = '@class.outer',
                            ['iC'] = '@class.inner',
                            ['ac'] = '@conditional.outer',
                            ['ic'] = '@conditional.inner',
                            ['ab'] = '@block.outer',
                            ['ib'] = '@block.inner',
                            ['al'] = '@loop.outer',
                            ['il'] = '@loop.inner',
                            ['is'] = '@statement.inner',
                            ['as'] = '@statement.outer',
                            ['am'] = '@call.outer',
                            ['im'] = '@call.inner',
                            ['ad'] = '@comment.outer',
                            ['id'] = '@comment.inner',
                        },
                    },
                    move = {
                        enable = true,
                        set_jumps = false,
                        goto_next_start = {
                            [']f'] = '@function.outer',
                            [']C'] = '@class.outer',
                            ['<down>'] = '@function.outer',
                            ['<right>'] = '@class.outer',
                        },
                        goto_previous_start = {
                            ['[f'] = '@function.outer',
                            ['[C'] = '@class.outer',
                            ['<up>'] = '@function.outer',
                            ['<left>'] = '@class.outer',
                        },
                    },
                    swap = {
                        enable = true,
                        swap_next = {
                            ['<leader>>'] = '@parameter.inner',
                            ['<leader>f>'] = '@function.outer',
                        },
                        swap_previous = {
                            ['<leader><'] = '@parameter.inner',
                            ['<leader>f<'] = '@function.outer',
                        },
                    },
                },
                autopairs = { enable = true },
                context_commentstring = {
                    enable = true,
                    enable_autocmd = false,
                },
                tree_setter = {
                    enable = true,
                },
            }

            -- use treesitter highlighting for markdown in Octo
            vim.treesitter.language.register('markdown', 'octo')
        end,
    },
}
