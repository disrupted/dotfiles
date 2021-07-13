local M = {}

function M.config()
    vim.cmd [[packadd nvim-treesitter-refactor]]
    vim.cmd [[packadd nvim-treesitter-textobjects]]
    require('nvim-treesitter.configs').setup {
        ensure_installed = 'maintained',
        highlight = { enable = true },
        indent = { enable = true },
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
                    goto_next_usage = '<space>n',
                    goto_previous_usage = '<space>N',
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
                    -- Or you can define your own textobjects like this
                    -- [[
                    ['iF'] = {
                        python = '(function_definition) @function',
                        cpp = '(function_definition) @function',
                        c = '(function_definition) @function',
                        java = '(method_declaration) @function',
                    },
                    -- ]]
                },
            },
            swap = {
                enable = true,
                swap_next = { ['<Leader>>'] = '@parameter.inner' },
                swap_previous = { ['<Leader><'] = '@parameter.inner' },
            },
        },
    }
end

return M
