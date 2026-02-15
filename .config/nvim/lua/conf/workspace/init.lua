local M = {}

---@alias detect_project.Opts.Markers table<string, (string|fun(name: string, path: string): boolean)[]> mapping of filetype to marker files or directories that mark a certain project type

---@type detect_project.Opts.Markers
local default_workspace_markers = {
    uv = { 'uv.lock' },
    poetry = { 'poetry.lock' },
    cargo = { 'Cargo.lock' },
    bun = { 'bun.lock' },
    xcode = {
        function(name)
            return name:match '%.xcodeproj$' ~= nil
        end,
    },
    nvim = { '.emmyrc.json' },
}

local workspace_to_filetype = {
    uv = 'python',
    poetry = 'python',
    cargo = 'rust',
    bun = 'javascript',
    xcode = 'swift',
    nvim = 'lua',
}

---@type detect_project.Opts.Markers
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
---@field markers? detect_project.Opts.Markers
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
---@return string detected filetypes of current project
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
    for workspace_type, files in pairs(default_workspace_markers) do
        local root = vim.fs.root(cwd, files)
        if root then
            vim.g.workspace_type = workspace_type
            vim.g.project_filetype = workspace_to_filetype[workspace_type]
            return root
        end
    end
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

--- Find a managed tab by name
---@param name string
---@return integer? handle tabpage handle, or nil if not found
local function find_tab(name)
    for _, handle in ipairs(vim.api.nvim_list_tabpages()) do
        local ok, tabname =
            pcall(vim.api.nvim_tabpage_get_var, handle, 'tabname')
        if ok and tabname == name then
            return handle
        end
    end
    return nil
end

--- Find a managed tab by name, creating it on demand if it doesn't exist
---@param name string
---@return integer handle tabpage handle
local function find_or_create_tab(name)
    local handle = find_tab(name)
    if handle then
        return handle
    end
    vim.cmd.tabnew()
    handle = vim.api.nvim_get_current_tabpage()
    vim.api.nvim_tabpage_set_var(handle, 'tabname', name)
    Snacks.notify(
        { ('created tab %q'):format(name) },
        { title = 'Workspace', level = 'debug' }
    )
    return handle
end

--- Get the managed tab name for a tabpage, or nil if unmanaged
---@param handle integer
---@return string?
local function get_tab_name(handle)
    local ok, tabname =
        pcall(vim.api.nvim_tabpage_get_var, handle, 'tabname')
    if ok then
        return tabname
    end
    return nil
end

--- Check if a file path looks like a test file
---@param filepath string
---@return boolean
local function is_test_file(filepath)
    local filename = vim.fs.basename(filepath):lower()
    local name_no_ext = filename:match '^(.+)%.' or filename
    -- test_foo.py, tests_foo.py
    if name_no_ext:match '^tests?[_%-%.]' then
        return true
    end
    -- foo_test.py, foo_test.go
    if name_no_ext:match '[_%-%.]tests?$' then
        return true
    end
    -- directory contains /test/ or /tests/
    local dir = filepath:lower()
    if dir:match '[/\\]tests?[/\\]' then
        return true
    end
    return false
end

local moving = false

---@param bufnr integer
---@param dest_name string managed tab name (e.g. 'code', 'tests')
local function move_buf_to_tab(bufnr, dest_name)
    moving = true
    vim.schedule(function()
        local scope_core = require('scope.core')
        local scope_utils = require('scope.utils')
        local source_tab = vim.api.nvim_get_current_tabpage()
        local source_name = get_tab_name(source_tab) or '?'

        -- 1. snapshot current tab into scope's cache so it's up to date
        scope_core.cache[source_tab] = scope_utils.get_valid_buffers()

        -- 2. remove bufnr from the source tab's cache
        scope_core.cache[source_tab] = vim.tbl_filter(function(b)
            return b ~= bufnr
        end, scope_core.cache[source_tab])

        -- 3. if source tab would be empty, create a placeholder buffer
        if #scope_core.cache[source_tab] == 0 then
            vim.cmd.enew()
            vim.bo.buflisted = true
            scope_core.cache[source_tab] =
                scope_utils.get_valid_buffers()
        end

        -- 4. switch away from bufnr in the source tab
        if vim.api.nvim_get_current_buf() == bufnr then
            vim.cmd.bprevious()
        end

        -- 5. find or create the target tab, add bufnr to its cache
        local target = find_or_create_tab(dest_name)
        local target_cache = scope_core.cache[target] or {}
        if not vim.list_contains(target_cache, bufnr) then
            target_cache[#target_cache + 1] = bufnr
            scope_core.cache[target] = target_cache
        end

        -- 6. switch to the target tab — scope's TabLeave/TabEnter will
        --    use our updated caches
        vim.api.nvim_set_current_tabpage(target)
        vim.api.nvim_set_current_buf(bufnr)

        moving = false

        Snacks.notify(
            {
                ('moved buf %d from tab %q to tab %q'):format(
                    bufnr,
                    source_name,
                    dest_name
                ),
            },
            { title = 'Workspace', level = 'debug' }
        )
    end)
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
        string.format(
            '%s [%s %s]',
            vim.g.workspace_root,
            vim.g.workspace_type,
            vim.g.project_filetype
        ),
    }, { title = 'Workspace', level = 'debug' })

    local argv = vim.fn.argv(0)
    if type(argv) == 'string' and argv:match '.git/COMMIT_EDITMSG' ~= nil then
        return
    end

    require('conf.hotreload').setup()

    vim.g.project_tabs = true
    if not vim.g.project_tabs or not vim.g.workspace_type then
        return
    end

    local managed_buffers = {}

    -- label the initial tab as 'code'
    vim.api.nvim_tabpage_set_var(0, 'tabname', 'code')

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
            -- skip non-file buffers
            if vim.bo[args.buf].buftype ~= '' then
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
            -- skip if we're already moving a buffer
            if moving then
                return
            end
            -- skip non-file buffers
            if vim.bo[args.buf].buftype ~= '' then
                return
            end

            local current_tab = vim.api.nvim_get_current_tabpage()
            local current_name = get_tab_name(current_tab)
            -- skip unmanaged tabs (user-created without a tabname)
            if not current_name then
                return
            end

            if managed_buffers[args.buf] then
                local dest_name = is_test_file(args.file) and 'tests'
                    or 'code'
                if current_name ~= dest_name then
                    move_buf_to_tab(args.buf, dest_name)
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
