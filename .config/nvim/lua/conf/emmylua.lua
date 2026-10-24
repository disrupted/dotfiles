--- Generates `.luarc.json` with the workspace libraries of all `vim.pack` plugins.
--- `.emmyrc.json` holds the other settings. EmmyLua merges both files.
local M = {}

local RC = vim.fs.joinpath(vim.fn.stdpath('config'), '.luarc.json')

--- One entry per plugin: a library path is a module root, so the parent `opt`
--- directory would only resolve modules through fuzzy matching.
---@return string[]
function M.library()
    local library = {}
    for _, plug in ipairs(vim.pack.get(nil, { info = false })) do
        local path = vim.fs.joinpath(plug.path, 'lua')
        if vim.uv.fs_stat(path) then -- lockfile may outlive the directory
            library[#library + 1] = vim.fn.fnamemodify(path, ':~')
        end
    end
    table.sort(library)
    table.insert(library, 1, '$VIMRUNTIME')
    return library
end

function M.write()
    local encoded = vim.json.encode({ workspace = { library = M.library() } })
    local ok, current = pcall(vim.fn.readfile, RC)
    if ok and table.concat(current, '\n') == encoded then
        return
    end
    vim.fn.writefile({ encoded }, RC)
end

function M.setup()
    M.write()
    vim.api.nvim_create_autocmd('PackChanged', {
        group = vim.api.nvim_create_augroup('EmmyluaLibrary', {}),
        callback = function(args)
            if args.data.kind ~= 'update' then -- update keeps the plugin path
                M.write()
            end
        end,
    })
end

return M
