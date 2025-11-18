vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup(
        'OverseerPyprojectLockOnSave',
        { clear = true }
    ),
    pattern = 'pyproject.toml',
    callback = function()
        local overseer = require 'overseer'
        if vim.fn.executable 'uv' == 1 and vim.uv.fs_stat 'uv.lock' ~= nil then
            overseer.run_task { name = 'uv' }
        elseif
            vim.fn.executable 'poetry' == 1
            and vim.uv.fs_stat 'poetry.lock' ~= nil
        then
            overseer.run_task { name = 'Poetry' }
        else
            Snacks.notify.warn('Invalid pyproject', { title = 'Overseer' })
        end
    end,
})
