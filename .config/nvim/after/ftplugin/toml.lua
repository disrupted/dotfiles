vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup(
        'OverseerPoetryLockOnSave',
        { clear = true }
    ),
    pattern = 'pyproject.toml',
    callback = function()
        local overseer = require 'overseer'
        overseer.run_template({ name = 'Poetry lock' }, function(task)
            if not task then
                Snacks.notify.warn(
                    'Not a valid Poetry pyproject',
                    { title = 'Overseer' }
                )
            end
        end)
    end,
})
