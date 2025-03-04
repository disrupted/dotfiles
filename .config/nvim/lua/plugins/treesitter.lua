local icons = require 'conf.icons'

---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'nvim-treesitter/nvim-treesitter',
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
        },
        config = function(_, opts)
            require('nvim-treesitter.configs').setup(opts)
            require('which-key').add {
                { '<CR>', desc = 'Increment selection', mode = { 'x', 'n' } },
                { '<BS>', desc = 'Decrement selection', mode = 'x' },
            }

            -- the filetype on the RHS will use the parser and queries on the LHS
            vim.treesitter.language.register('bash', 'zsh')
            vim.treesitter.language.register('terraform', 'terraform-vars')
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        event = { 'BufReadPost', 'BufNewFile', 'FileType' },
        keys = {
            ']f',
            '[f',
            ']C',
            '[C',
            'zsp>',
            'zsp<',
            'zsf>',
            'zsf<',
        },
        init = function()
            require('which-key').add {
                { 'zs', group = 'Swap', icon = '󰓡' },
                { 'zsp', desc = 'Parameter', icon = icons.kinds.Variable },
                { 'zsp>', desc = 'Next', icon = icons.arrows.right },
                { 'zsp<', desc = 'Prev', icon = icons.arrows.left },
                { 'zsf', desc = 'Function', icon = icons.kinds.Function },
                { 'zsf>', desc = 'Next', icon = icons.arrows.right },
                { 'zsf<', desc = 'Prev', icon = icons.arrows.left },
            }
        end,
        opts = {
            select = {
                enable = true,
                disable = {},
                keymaps = {
                    -- capture groups defined in textobjects.scm
                    ['af'] = '@function.outer',
                    ['if'] = '@function.inner',
                    ['aC'] = '@class.outer',
                    ['iC'] = '@class.inner',
                    ['ap'] = '@parameter.outer',
                    ['ip'] = '@parameter.inner',
                    ['ao'] = '@conditional.outer',
                    ['io'] = '@conditional.inner',
                    ['ab'] = '@block.outer',
                    ['ib'] = '@block.inner',
                    ['al'] = '@loop.outer',
                    ['il'] = '@loop.inner',
                    ['is'] = '@statement.inner',
                    ['as'] = '@statement.outer',
                    ['am'] = '@call.outer',
                    ['im'] = '@call.inner',
                    ['ac'] = '@comment.outer',
                    ['ic'] = '@comment.inner',
                },
                selection_modes = {
                    ['@function.outer'] = 'V', -- linewise
                    ['@class.outer'] = 'V', -- linewise
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
                    ['zsp>'] = '@parameter.inner',
                    ['zsf>'] = '@function.outer',
                },
                swap_previous = {
                    ['zsp<'] = '@parameter.inner',
                    ['zsf<'] = '@function.outer',
                },
            },
        },
        config = function(_, opts)
            ---@diagnostic disable-next-line: missing-fields
            require('nvim-treesitter.configs').setup { textobjects = opts }
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-refactor',
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
        'filNaj/tree-setter',
        enabled = false,
        event = 'InsertEnter',
        opts = { enable = true },
        config = function(_, opts)
            ---@diagnostic disable-next-line: missing-fields
            require('nvim-treesitter.configs').setup {
                tree_setter = opts,
            }
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
