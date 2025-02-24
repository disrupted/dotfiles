local M = {}

---@alias detect_project.Opts.FileTypeMarkers table<string, string[]> mapping of filetype to marker files or directories that mark a certain project type

---@type detect_project.Opts.FileTypeMarkers
local default_project_markers = {
    python = { 'pyproject.toml' },
    rust = { 'Cargo.toml' },
    javascript = { 'package.json' },
}

---@class detect_project.Opts
---@field markers? detect_project.Opts.FileTypeMarkers
---@field all? boolean include all filetypes

---@type detect_project.Opts
local default_opts = {
    markers = default_project_markers,
    all = false,
}

-- Detect project type of cwd
---@param opts? detect_project.Opts
---@return string[] detected filetypes of current project
M.project_filetypes = function(opts)
    ---@type detect_project.Opts
    opts = vim.tbl_extend('keep', opts or {}, default_opts)

    -- check open buffers
    local project_filetypes = vim.iter(vim.api.nvim_list_bufs())
        :filter(vim.api.nvim_buf_is_loaded)
        :filter(function(buf)
            return vim.bo[buf].buftype ~= 'nofile'
                and vim.bo[buf].filetype ~= ''
        end)
        :map(function(buf)
            return vim.bo[buf].filetype
        end)
        :totable()

    -- check marker files
    for filetype, files in pairs(opts.markers) do
        if
            not vim.list_contains(project_filetypes, filetype)
            and vim.iter(files):any(function(file)
                return vim.uv.fs_stat(file) ~= nil
            end)
        then
            table.insert(project_filetypes, filetype)
        end
    end

    if opts.all then
        return project_filetypes
    end

    return vim.iter(project_filetypes)
        :filter(function(ft)
            return opts.markers[ft] ~= nil
        end)
        :totable()
end

return M
