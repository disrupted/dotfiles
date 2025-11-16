vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup(
        'OverseerPyprojectLockOnSave',
        { clear = true }
    ),
    pattern = 'pyproject.toml',
    callback = function()
        local overseer = require 'overseer'
        overseer.run_task({ name = 'uv' }, function(task_uv)
            if not task_uv then
                overseer.run_task({ name = 'Poetry' }, function(task_poetry)
                    if not task_poetry then
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
