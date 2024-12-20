vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup(
        'OverseerPyprojectLockOnSave',
        { clear = true }
    ),
    pattern = 'pyproject.toml',
    callback = function()
        local overseer = require 'overseer'
        overseer.run_template({ name = 'uv' }, function(task)
            if not task then
                overseer.run_template({ name = 'Poetry' }, function(task)
                    if not task then
                        Snacks.notify.warn(
                            'Invalid pyproject',
                            { title = 'Overseer' }
                        )
                    end
                end)
            end
        end)
    end,
})
