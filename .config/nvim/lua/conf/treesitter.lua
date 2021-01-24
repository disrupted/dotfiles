local M = {}

function M.config()
    require'nvim-treesitter.configs'.setup {
        ensure_installed = 'maintained',
        highlight = {enable = true},
        indent = {enable = true},
        incremental_selection = {
            enable = true,
            disable = {},
            keymaps = { -- mappings for incremental selection (visual mappings)
                init_selection = "<M-v>", -- maps in normal mode to init the node/scope selection
                node_incremental = "<M-v>", -- increment to the upper named parent
                scope_incremental = "<C-M-v>", -- increment to the upper scope (as defined in locals.scm)
                node_decremental = "<M-V>" -- decrement to the previous node
            }
        },
        refactor = {
            highlight_definitions = {enable = true},
            highlight_current_scope = {enable = false},
            smart_rename = {
                enable = true,
                keymaps = {
                    smart_rename = "grr" -- mapping to rename reference under cursor
                }
            },
            navigation = {
                enable = true,
                keymaps = {
                    goto_definition = "gnd", -- mapping to go to definition of symbol under cursor
                    list_definitions = "gnD" -- mapping to list all definitions in current file
                }
            }
        },
        textobjects = { -- syntax-aware textobjects
            select = {
                enable = true,
                disable = {},
                keymaps = {
                    -- You can use the capture groups defined in textobjects.scm
                    ["af"] = "@function.outer",
                    ["if"] = "@function.inner",
                    ["aC"] = "@class.outer",
                    ["iC"] = "@class.inner",
                    ["ac"] = "@conditional.outer",
                    ["ic"] = "@conditional.inner",
                    ["ae"] = "@block.outer",
                    ["ie"] = "@block.inner",
                    ["al"] = "@loop.outer",
                    ["il"] = "@loop.inner",
                    ["is"] = "@statement.inner",
                    ["as"] = "@statement.outer",
                    ["am"] = "@call.outer",
                    ["im"] = "@call.inner",
                    ["ad"] = "@comment.outer",
                    ["id"] = "@comment.inner",
                    -- Or you can define your own textobjects like this
                    -- [[
                    ["iF"] = {
                        python = "(function_definition) @function",
                        cpp = "(function_definition) @function",
                        c = "(function_definition) @function",
                        java = "(method_declaration) @function"
                    }
                    -- ]]
                }
            },
            swap = {
                enable = true,
                swap_next = {["<Leader>s"] = "@parameter.inner"},
                swap_previous = {["<Leader>S"] = "@parameter.inner"}
            }
        }
    }
end

return M

