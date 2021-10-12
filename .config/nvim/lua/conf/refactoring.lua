local M = {}

-- telescope refactoring helper
local function refactor(prompt_bufnr)
    local content = require('telescope.actions.state').get_selected_entry(
        prompt_bufnr
    )
    require('telescope.actions').close(prompt_bufnr)
    require('refactoring').refactor(content.value)
end

_G.refactor_telescope = function()
    local opts = require('telescope.themes').get_cursor() -- set personal telescope options
    require('telescope.pickers').new(opts, {
        prompt_title = 'refactors',
        finder = require('telescope.finders').new_table {
            results = require('refactoring').get_refactors(),
        },
        sorter = require('telescope.config').values.generic_sorter(opts),
        attach_mappings = function(_, map)
            map('i', '<CR>', refactor)
            map('n', '<CR>', refactor)
            return true
        end,
    }):find()
end

function M.setup()
    local map = require('utils').map
    map(
        'v',
        '<leader>re',
        '<esc><cmd>lua require("refactoring").refactor("Extract Function")<CR>'
    )
    map('v', '<leader>rt', '<esc><cmd>lua _G.refactor_telescope()<CR>')
end

function M.config()
    require('refactoring').setup()
end

return M
