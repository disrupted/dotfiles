local M = {}

function M.setup()
    vim.keymap.set('n', '<leader>nf', function()
        require('neogen').generate()
    end)
end

function M.config()
    require('neogen').setup {
        snippet_engine = 'luasnip',
        languages = {
            python = {
                template = {
                    annotation_convention = 'reST',
                },
            },
        },
    }
end

return M
