local M = {}

function M.config()
    require('nvim-treesitter.configs').setup {
        ensure_installed = {
            'bash',
            'bibtex',
            'c',
            'cmake',
            'comment',
            'css',
            'diff',
            'dockerfile',
            'dot',
            'fennel',
            'git_rebase',
            'go',
            'graphql',
            'help',
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
            'toml',
            'tsx',
            'typescript',
            'vim',
            'yaml',
        },
        highlight = { enable = true },
        -- indent = { enable = true, disable = { 'python', 'yaml' } },
        indent = { enable = false },
        yati = {
            enable = true,
            default_lazy = true,
            default_fallback = 'auto',
        },
        incremental_selection = {
            enable = true,
            disable = {},
            keymaps = { -- mappings for incremental selection (visual mappings)
                init_selection = '<CR>', -- maps in normal mode to init the node/scope selection
                node_incremental = '<CR>', -- increment to the upper named parent
                scope_incremental = '<TAB>', -- increment to the upper scope (as defined in locals.scm)
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
                    -- [']]'] = '@class.outer',
                },
                goto_previous_start = {
                    ['[f'] = '@function.outer',
                    -- ['[['] = '@class.outer',
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
        playground = {
            enable = true,
            disable = {},
            updatetime = 25,
            persist_queries = false,
            keybindings = {
                toggle_query_editor = 'o',
                toggle_hl_groups = 'i',
                toggle_injected_languages = 't',
                toggle_anonymous_nodes = 'a',
                toggle_language_display = 'I',
                focus_language = 'f',
                unfocus_language = 'F',
                update = 'R',
                goto_node = '<CR>',
                show_help = '?',
            },
        },
        context_commentstring = {
            enable = true,
            enable_autocmd = false,
        },
        tree_setter = {
            enable = false,
        },
    }

    local ft_to_parser =
        require('nvim-treesitter.parsers').filetype_to_parsername
    -- use treesitter highlighting for markdown in Octo
    ft_to_parser.octo = 'markdown'
end

return M
