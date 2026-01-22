local M = {}

---@alias detect_project.Opts.FileTypeMarkers table<string, (string|fun(name: string, path: string): boolean)[]> mapping of filetype to marker files or directories that mark a certain project type

---@type detect_project.Opts.FileTypeMarkers
local default_project_markers = {
    python = { 'pyproject.toml' },
    lua = { '.luarc.json', '.luarc.jsonc', '.stylua.toml', 'stylua.toml' },
    rust = { 'Cargo.toml' },
    javascript = { 'package.json' },
    swift = {
        function(name)
            return name:match '%.xcodeproj$' ~= nil
        end,
    },
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
            and vim.iter(files):any(function(file_predicate)
                if type(file_predicate) == 'function' then
                    return false -- TODO: handle these
                end
                return vim.uv.fs_stat(file_predicate) ~= nil
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
            vim.g.project_filetype = filetype
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

---@param names string[]
local function init_tabs(names)
    for i, name in ipairs(names) do
        if i > 1 then
            vim.cmd.tabnew()
        end
        vim.api.nvim_tabpage_set_var(0, 'tabname', name)
    end
    vim.api.nvim_set_current_tabpage(1)
end

---@param bufnr integer
---@param tabnr integer
local function move_buf_to_tab(bufnr, tabnr)
    Snacks.notify(
        { ('move buf %d to tab %d'):format(bufnr, tabnr) },
        { title = 'Workspace', level = 'debug' }
    )
    local target_handle = vim.api.nvim_list_tabpages()[tabnr]
    vim.defer_fn(function()
        require('scope.core').move_buf(bufnr, target_handle)
        vim.api.nvim_set_current_tabpage(tabnr)
        vim.api.nvim_set_current_buf(bufnr)
    end, 0)
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
    -- vim.api.nvim_set_current_dir(vim.g.workspace_root)

    Snacks.notify({
        string.format('Project filetype: %s', vim.g.project_filetype),
        string.format('Workspace root: %s', vim.g.workspace_root),
        string.format('Git repo: %s', vim.g.git_repo),
    }, { level = 'debug' })

    local argv = vim.fn.argv(0)
    if type(argv) == 'string' and argv:match '.git/COMMIT_EDITMSG' ~= nil then
        return
    end

    require('conf.hotreload').setup { path = cwd }

    vim.g.project_tabs = false
    if not vim.g.project_tabs or not vim.g.project_filetype then
        return
    end

    local managed_buffers = {}
    local managed_tabs = {
        code = {
            idx = 1,
            name = 'code',
        },
        tests = {
            idx = 2,
            name = 'tests',
        },
    }
    local tab_names = {}
    for _, tab in pairs(managed_tabs) do
        tab_names[tab.idx] = tab.name
    end
    init_tabs(tab_names)

    local tabmanager_augroup = vim.api.nvim_create_augroup('TabManager', {})
    vim.api.nvim_create_autocmd('BufAdd', {
        group = tabmanager_augroup,
        callback = function(args)
            if managed_buffers[args.buf] then
                Snacks.notify(
                    { 'already managed buffer', vim.inspect(args) },
                    { title = 'Workspace', level = 'debug' }
                )
                return
            end

            if
                args.file ~= ''
                and vim.fs.relpath(vim.g.workspace_root, args.file)
            then
                Snacks.notify(
                    { 'add managed buffer', vim.inspect(args) },
                    { title = 'Workspace', level = 'debug' }
                )
                managed_buffers[args.buf] = true
            end
        end,
    })

    vim.api.nvim_create_autocmd('BufEnter', {
        group = tabmanager_augroup,
        callback = function(args)
            local tabnr = vim.api.nvim_get_current_tabpage()
            if tabnr > #tab_names then
                return
            end
            if managed_buffers[args.buf] then
                local dest = managed_tabs.code
                local filename = args.file:lower()
                if filename:match '[^%w]tests?[^%w]' then
                    dest = managed_tabs.tests
                end
                if tabnr ~= dest.idx then
                    move_buf_to_tab(args.buf, dest.idx)
                end
            end
        end,
    })

    vim.api.nvim_create_autocmd('BufDelete', {
        group = tabmanager_augroup,
        desc = 'Clean up when buffers are deleted',
        callback = function(args)
            Snacks.notify(
                { ('delete managed buffer %d'):format(args.buf) },
                { title = 'Workspace', level = 'debug' }
            )
            managed_buffers[args.buf] = nil
        end,
    })
end

return M
