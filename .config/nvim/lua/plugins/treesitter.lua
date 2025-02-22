---@module 'lazy.types'
---@type LazySpec[]
return {
    { 'filNaj/tree-setter', enabled = false },
    {
        'windwp/nvim-ts-autotag',
        enabled = false,
        event = 'InsertEnter',
        opts = {},
    },
    {
        'nvim-treesitter/nvim-treesitter',
        event = { 'BufRead', 'BufNewFile', 'FileType' },
        dependencies = {
            'nvim-treesitter/nvim-treesitter-refactor',
            'nvim-treesitter/nvim-treesitter-textobjects',
        },
        build = ':TSUpdate',
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
                'terraform',
                'toml',
                'tmux',
                'tsx',
                'typescript',
                'vim',
                'vimdoc',
                'xml',
                'yaml',
            },
            highlight = { enable = true },
            indent = { enable = true, disable = { 'yaml' } },
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
            refactor = {
                highlight_definitions = { enable = false },
                highlight_current_scope = { enable = false },
                smart_rename = {
                    enable = true,
                    keymaps = {
                        smart_rename = '<leader>R', -- mapping to rename reference under cursor
                    },
                },
                navigation = {
                    enable = false,
                    keymaps = {
                        goto_definition = 'gnd', -- mapping to go to definition of symbol under cursor
                        list_definitions = 'gnD', -- mapping to list all definitions in current file
                        goto_next_usage = '<C-n>',
                        goto_previous_usage = '<C-p>',
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
                        [']f'] = {
                            query = '@function.outer',
                            desc = 'Next function',
                        },
                        [']C'] = {
                            query = '@class.outer',
                            desc = 'Next class',
                        },
                    },
                    goto_previous_start = {
                        ['[f'] = {
                            query = '@function.outer',
                            desc = 'Prev function',
                        },
                        ['[C'] = {
                            query = '@class.outer',
                            desc = 'Prev class',
                        },
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
            tree_setter = { enable = true },
        },
        config = function(_, opts)
            require('nvim-treesitter.configs').setup(opts)

            -- the filetype on the RHS will use the parser and queries on the LHS
            vim.treesitter.language.register('bash', 'zsh')
            vim.treesitter.language.register('terraform', 'terraform-vars')
            vim.treesitter.language.register('markdown', 'octo')
        end,
    },
    {
        'bezhermoso/tree-sitter-ghostty',
        ft = 'ghostty',
        build = 'make nvim_install',
    },
}
