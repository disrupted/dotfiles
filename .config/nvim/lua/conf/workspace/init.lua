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
M.find_or_create_tab = function(name)
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
    local ok, tabname = pcall(vim.api.nvim_tabpage_get_var, handle, 'tabname')
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
    if dir:match 'tests?[/\\]' then
        return true
    end
    return false
end

local moving = false

--- Track which tab each buffer has been assigned to (by name).
--- Once assigned, a buffer won't be moved again by the BufEnter handler.
---@type table<integer, string>
local buf_tab_assignment = {}

--- Cross-tab jump stack.  Records jumps that crossed tab boundaries so
--- that <C-o>/<C-i> can navigate back/forward across tabs.
---@class CrossTabJump
---@field source_tab string managed tab name
---@field source_buf integer buffer number
---@field source_pos integer[] {lnum, col}
---@field dest_tab string managed tab name
---@field dest_buf integer buffer number
---@field dest_pos integer[] {lnum, col}

---@type CrossTabJump[]
local cross_tab_jumps = {}
---@type integer
local cross_tab_pos = 0 -- 0 = before first entry

---@param bufnr integer
---@param dest_name string managed tab name (e.g. 'code', 'tests')
local function move_buf_to_tab(bufnr, dest_name)
    moving = true
    vim.schedule(function()
        local scope_core = require 'scope.core'
        local scope_utils = require 'scope.utils'
        local source_tab = vim.api.nvim_get_current_tabpage()
        local source_name = get_tab_name(source_tab) or '?'

        -- suppress scope's autocmds during the entire move
        pcall(vim.api.nvim_del_augroup_by_name, 'ScopeAU')

        -- Save the cursor position that the caller (e.g. LSP) set on the
        -- buffer before we navigate away from it in the source tab.
        local cursor_pos
        if vim.api.nvim_get_current_buf() == bufnr then
            cursor_pos = vim.api.nvim_win_get_cursor(0)
        end

        -- 1. Record the cross-tab jump, then unlist the buffer and switch
        --    away from it in the source tab.
        vim.api.nvim_set_option_value('buflisted', false, { buf = bufnr })
        if vim.api.nvim_get_current_buf() == bufnr then
            -- Try to find the position we jumped FROM via the jumplist
            local source_buf = nil
            local source_pos = nil
            local jumplist, pos = unpack(vim.fn.getjumplist())
            if pos > 0 and pos == #jumplist then
                local prev = jumplist[pos]
                if
                    prev
                    and vim.api.nvim_buf_is_valid(prev.bufnr)
                    and prev.bufnr ~= bufnr
                then
                    source_buf = prev.bufnr
                    source_pos = { prev.lnum, prev.col }
                end
            end

            -- Record the cross-tab jump (truncate any forward entries)
            if source_buf then
                for i = #cross_tab_jumps, cross_tab_pos + 1, -1 do
                    cross_tab_jumps[i] = nil
                end
                cross_tab_pos = cross_tab_pos + 1
                cross_tab_jumps[cross_tab_pos] = {
                    source_tab = source_name,
                    source_buf = source_buf,
                    source_pos = source_pos,
                    dest_tab = dest_name,
                    dest_buf = bufnr,
                    dest_pos = cursor_pos or { 1, 0 },
                }
            end

            -- Navigate away from the buffer in the source tab
            if source_buf then
                vim.cmd [[exe "normal! \<C-o>"]]
            elseif #scope_utils.get_valid_buffers() == 0 then
                vim.cmd.enew()
                vim.bo.buflisted = true
            else
                vim.cmd.bprevious()
            end
        end

        -- 2. update scope's cache for source tab (without the moved buffer)
        scope_core.cache[source_tab] = scope_utils.get_valid_buffers()

        -- 3. find or create the target tab
        --    NOTE: tabnew() will inherit currently listed buffers — we
        --    clean those up after switching instead of unlisting them
        --    beforehand (unlisting causes cascading wipeouts)
        local target = M.find_or_create_tab(dest_name)
        if vim.api.nvim_get_current_tabpage() ~= target then
            vim.api.nvim_set_current_tabpage(target)
        end

        -- 4. unlist everything that doesn't belong in the target tab,
        --    then relist what does belong (from cache + moved buffer)
        for _, b in ipairs(scope_utils.get_valid_buffers()) do
            vim.api.nvim_set_option_value('buflisted', false, { buf = b })
        end
        local target_cache = scope_core.cache[target] or {}
        for _, b in ipairs(target_cache) do
            if vim.api.nvim_buf_is_valid(b) then
                vim.api.nvim_set_option_value('buflisted', true, { buf = b })
            end
        end
        vim.api.nvim_set_option_value('buflisted', true, { buf = bufnr })
        vim.cmd('keepjumps buffer ' .. bufnr)

        -- Restore the cursor position (e.g. LSP definition target)
        if cursor_pos then
            local line_count = vim.api.nvim_buf_line_count(bufnr)
            if cursor_pos[1] <= line_count then
                vim.api.nvim_win_set_cursor(0, cursor_pos)
            end
        end

        -- 5. update scope's cache for target tab
        scope_core.cache[target] = scope_utils.get_valid_buffers()

        -- 6. mark buffer as assigned to destination tab
        buf_tab_assignment[bufnr] = dest_name

        -- 7. re-enable scope
        require('scope')._setup()

        moving = false

        Snacks.notify({
            ('moved buf %d from tab %q to tab %q'):format(
                bufnr,
                source_name,
                dest_name
            ),
        }, { title = 'Workspace', level = 'debug' })
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
                local dest_name = is_test_file(args.file) and 'tests' or 'code'
                -- skip if already assigned AND we're in the correct tab
                if
                    buf_tab_assignment[args.buf] == dest_name
                    and current_name == dest_name
                then
                    return
                end
                if current_name ~= dest_name then
                    move_buf_to_tab(args.buf, dest_name)
                else
                    -- buffer is in the right tab, just record it
                    buf_tab_assignment[args.buf] = dest_name
                end
            end
        end,
    })

    -- Tab-aware <C-o>/<C-i> mappings.
    -- When at the boundary of a cross-tab jump, switch tabs instead of
    -- using the native (per-window) jumplist.
    --- Execute a native jumplist navigation, skipping over any entries
    --- that belong in a different tab.
    ---@param backward boolean  true for <C-o>, false for <C-i>
    local function native_jump_filtered(backward)
        local current_name = get_tab_name(vim.api.nvim_get_current_tabpage())
        local key_code = vim.api.nvim_replace_termcodes(
            backward and '<C-o>' or '<C-i>',
            true,
            false,
            true
        )
        -- Try up to 100 times to skip cross-tab entries
        for _ = 1, 100 do
            local jumplist, pos = unpack(vim.fn.getjumplist())
            local idx = pos + (backward and 0 or 1)
            if idx < 1 or idx > #jumplist then
                return -- nothing left in this direction
            end
            local target_entry = jumplist[idx]
            if not target_entry then
                return
            end
            -- If the target buffer belongs in a different tab, silently
            -- advance the jumplist pointer past it and try again
            if
                current_name
                and vim.api.nvim_buf_is_valid(target_entry.bufnr)
                and buf_tab_assignment[target_entry.bufnr]
                and buf_tab_assignment[target_entry.bufnr] ~= current_name
            then
                vim.api.nvim_feedkeys(key_code, 'x', false)
            else
                -- Safe to land here
                vim.api.nvim_feedkeys(key_code, 'n', false)
                return
            end
        end
    end

    vim.keymap.set('n', '<C-o>', function()
        if cross_tab_pos > 0 then
            local entry = cross_tab_jumps[cross_tab_pos]
            local current_name =
                get_tab_name(vim.api.nvim_get_current_tabpage())
            if
                current_name == entry.dest_tab
                and vim.api.nvim_get_current_buf() == entry.dest_buf
            then
                local target = find_tab(entry.source_tab)
                if target then
                    cross_tab_pos = cross_tab_pos - 1
                    vim.api.nvim_set_current_tabpage(target)
                    if
                        vim.api.nvim_buf_is_valid(entry.source_buf)
                        and vim.api.nvim_get_current_buf()
                            ~= entry.source_buf
                    then
                        vim.cmd('keepjumps buffer ' .. entry.source_buf)
                    end
                    pcall(vim.api.nvim_win_set_cursor, 0, entry.source_pos)
                    return
                end
            end
        end
        native_jump_filtered(true)
    end, { desc = 'Jump back (tab-aware)' })

    vim.keymap.set('n', '<C-i>', function()
        if cross_tab_pos < #cross_tab_jumps then
            local entry = cross_tab_jumps[cross_tab_pos + 1]
            local current_name =
                get_tab_name(vim.api.nvim_get_current_tabpage())
            if
                current_name == entry.source_tab
                and vim.api.nvim_get_current_buf() == entry.source_buf
            then
                local target = find_tab(entry.dest_tab)
                if target then
                    cross_tab_pos = cross_tab_pos + 1
                    vim.api.nvim_set_current_tabpage(target)
                    if
                        vim.api.nvim_buf_is_valid(entry.dest_buf)
                        and vim.api.nvim_get_current_buf() ~= entry.dest_buf
                    then
                        vim.cmd('keepjumps buffer ' .. entry.dest_buf)
                    end
                    pcall(vim.api.nvim_win_set_cursor, 0, entry.dest_pos)
                    return
                end
            end
        end
        native_jump_filtered(false)
    end, { desc = 'Jump forward (tab-aware)' })

    vim.api.nvim_create_autocmd('BufWipeout', {
        group = tabmanager_augroup,
        desc = 'Clean up when buffers are wiped out',
        callback = function(args)
            if managed_buffers[args.buf] then
                Snacks.notify(
                    { ('wipeout managed buffer %d'):format(args.buf) },
                    { title = 'Workspace', level = 'debug' }
                )
            end
            managed_buffers[args.buf] = nil
            buf_tab_assignment[args.buf] = nil
            -- purge cross-tab jump entries referencing this buffer
            for i = #cross_tab_jumps, 1, -1 do
                local e = cross_tab_jumps[i]
                if e.source_buf == args.buf or e.dest_buf == args.buf then
                    table.remove(cross_tab_jumps, i)
                    if cross_tab_pos >= i then
                        cross_tab_pos = math.max(0, cross_tab_pos - 1)
                    end
                end
            end
        end,
    })
end

return M
