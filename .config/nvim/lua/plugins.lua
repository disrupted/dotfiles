local M = {}

---@return doze.Spec[]
function M.specs()
    local root = vim.fs.joinpath(vim.fn.stdpath('config'), 'lua', 'plugins')
    -- not vim.fn.glob: its ** expansion takes ~5 ms here
    local files = {} ---@type string[]
    for name, kind in vim.fs.dir(root, { depth = 10 }) do
        if kind == 'file' and name:sub(-4) == '.lua' then
            files[#files + 1] = vim.fs.joinpath(root, name)
        end
    end

    -- Spec order decides init order and breaks priority ties.
    table.sort(files)

    return vim.iter(files):map(dofile):totable()
end

function M.setup()
    require('doze').setup(M.specs())
end

return M
