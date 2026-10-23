local M = {}

---@return LazeSpec[]
function M.specs()
    local root = vim.fs.joinpath(vim.fn.stdpath('config'), 'lua', 'plugins')
    local files = vim.fn.glob(root .. '/**/*.lua', false, true)

    -- Keep startup deterministic; laze resolves dependencies by name.
    table.sort(files)

    return vim.iter(files):map(dofile):totable()
end

function M.setup()
    require('laze').setup(M.specs())
end

return M
