vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup(
        'OverseerTasksOnSave',
        { clear = false }
    ),
    pattern = 'pyproject.toml',
    callback = function()
        local overseer = require 'overseer'
        overseer.run_template({ name = 'Poetry lock' }, function(task)
            if not task then
                vim.notify('Not a valid Poetry pyproject', vim.log.levels.ERROR)
            end
        end)
    end,
})
