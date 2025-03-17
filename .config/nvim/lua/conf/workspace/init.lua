local M = {}

---@alias detect_project.Opts.FileTypeMarkers table<string, string[]> mapping of filetype to marker files or directories that mark a certain project type

---@type detect_project.Opts.FileTypeMarkers
local default_project_markers = {
    python = { 'pyproject.toml' },
    lua = { '.luarc.json', '.luarc.jsonc', '.stylua.toml', 'stylua.toml' },
    rust = { 'Cargo.toml' },
    javascript = { 'package.json' },
}

---@class detect_project.Opts
---@field markers? detect_project.Opts.FileTypeMarkers
---@field buffers? boolean check open buffers
---@field all? boolean include all filetypes

---@type detect_project.Opts
local default_opts = {
    markers = default_project_markers,
    buffers = true,
    all = false,
}

-- Detect project type of cwd
---@param opts? detect_project.Opts
---@return string[] detected filetypes of current project
M.project_filetypes = function(opts)
    ---@type detect_project.Opts
    opts = vim.tbl_extend('keep', opts or {}, default_opts)

    local project_filetypes = {}

    -- check open buffers
    if opts.buffers then
        project_filetypes = vim.iter(vim.api.nvim_list_bufs())
            :filter(vim.api.nvim_buf_is_loaded)
            :filter(function(buf)
                return vim.bo[buf].buftype ~= 'nofile'
                    and vim.bo[buf].filetype ~= ''
            end)
            :map(function(buf)
                return vim.bo[buf].filetype
            end)
            :totable()
    end

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

    -- include only requested filetypes
    return vim.iter(project_filetypes)
        :filter(function(ft)
            return opts.markers[ft] ~= nil
        end)
        :totable()
end

---@param cwd string
---@return string
M.get_root = function(cwd)
    for filetype, files in pairs(default_project_markers) do
        local root = vim.fs.root(cwd, files)
        if root then
            Snacks.notify(
                string.format('Detected %s project', filetype),
                { level = 'debug' }
            )
            return root
        end
    end
    if vim.g.git_repo then
        return vim.fs.dirname(vim.g.git_repo)
    end
    local config = vim.fn.stdpath 'config'
    local rel_to_config = vim.fs.relpath(config, cwd)
    if rel_to_config then
        return config
    end
    return cwd
end

M.setup = function()
    local cwd = vim.uv.cwd()
    if not cwd then
        Snacks.notify.error 'Invalid CWD'
        return
    end
    require('git').setup(cwd)
    vim.g.workspace_root = M.get_root(cwd)
    if not vim.g.git_repo then
        require('yadm').setup()
    end
    -- change global working directory to workspace root
    vim.api.nvim_set_current_dir(vim.g.workspace_root)
    Snacks.notify({
        'Workspace root: ' .. vim.g.workspace_root,
        'Git repo: ' .. vim.g.git_repo,
    }, { level = 'debug' })
end

return M
