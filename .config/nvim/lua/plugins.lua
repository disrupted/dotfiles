local M = {}

---@return doze.Spec[]
function M.specs()
    local root = vim.fs.joinpath(vim.fn.stdpath('config'), 'lua', 'plugins')
    local files = vim.fn.glob(root .. '/**/*.lua', false, true)

    -- Spec order decides init order and breaks priority ties.
    table.sort(files)

    return vim.iter(files):map(dofile):totable()
end

function M.setup()
    require('doze').setup(M.specs())
end

return M
