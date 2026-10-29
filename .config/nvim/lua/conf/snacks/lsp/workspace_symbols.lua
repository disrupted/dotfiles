--- Workspace symbols across all project LSP clients.
---
--- In a monorepo several servers provide workspace symbols (e.g. ty for
--- backend/, tsc for frontend/). By default all of them are queried and the
--- results ranked together; `<C-l>` cycles to a single server and back.
local M = {}

---@param root string
---@param scope_dir string?
---@return string?
local function scope_label(root, scope_dir)
    if not scope_dir then
        return nil
    end
    local rel = vim.fs.relpath(root, scope_dir)
    if rel then
        return rel == '.' and './' or (rel .. '/')
    end
    return scope_dir
end

---@param clients vim.lsp.Client[]
---@return string[] unique client names in order
local function client_names(clients)
    local names = {}
    for _, client in ipairs(clients) do
        if not vim.list_contains(names, client.name) then
            names[#names + 1] = client.name
        end
    end
    return names
end

---@param clients vim.lsp.Client[]
---@param root string
---@param scope_dir string?
---@return string
local function picker_title(clients, root, scope_dir)
    local title = 'LSP Workspace Symbols'
    if #clients > 0 then
        title = ('%s [%s]'):format(title, table.concat(client_names(clients), '+'))
    end
    local label = scope_label(root, scope_dir)
    if label then
        title = ('%s [%s]'):format(title, label)
    end
    return title
end

---@param file string?
---@param scope_dir string
---@return boolean
local function in_scope(file, scope_dir)
    if type(file) ~= 'string' or file == '' then
        return false
    end
    return vim.fs.relpath(scope_dir, file) ~= nil
end

---@param client vim.lsp.Client
---@return boolean
local function supports_workspace_symbols(client)
    local cap = client.server_capabilities
    return cap ~= nil and cap.workspaceSymbolProvider ~= nil
end

---@param client vim.lsp.Client
---@return string[]
local function client_filetypes(client)
    -- client.config is a vim.lsp.ClientConfig, which doesn't declare
    -- filetypes in the runtime types
    return client.config and (client.config --[[@as vim.lsp.Config]]).filetypes or {}
end

--- Clients providing workspace symbols for the project at `root`: rooted
--- inside it and serving one of the project's filetypes.
---@param root string
---@param only? string restrict to clients with this name
---@return vim.lsp.Client[]
local function project_clients(root, only)
    local filetypes = require('conf.workspace').project_filetypes({ buffers = false })
    local clients = vim.iter(vim.lsp.get_clients())
        :filter(function(client)
            if client:is_stopped() or not supports_workspace_symbols(client) then
                return false
            end
            if only and client.name ~= only then
                return false
            end
            if not client.root_dir or not vim.fs.relpath(root, client.root_dir) then
                return false
            end
            if #filetypes == 0 then
                return true
            end
            return vim.iter(client_filetypes(client)):any(function(ft)
                return vim.list_contains(filetypes, ft)
            end)
        end)
        :totable()
    -- stable order (by root, then name) regardless of which server started first
    table.sort(clients, function(a, b)
        if a.root_dir ~= b.root_dir then
            return a.root_dir < b.root_dir
        end
        return a.name < b.name
    end)
    return clients
end

--- Symbol kind filter for a client, from the picker's per-filetype filters.
---@param filters table<string, boolean|string[]>
---@param client vim.lsp.Client
---@return boolean|string[]
local function kind_filter(filters, client)
    for _, ft in ipairs(client_filetypes(client)) do
        if filters[ft] ~= nil then
            return filters[ft]
        end
    end
    if filters.default ~= nil then
        return filters.default
    end
    return true
end

--- The finder coroutine may run in a fast event context, so everything that
--- needs the main loop (resolving clients, loading the fuzzy backend) happens
--- beforehand; `state.clients` is kept up to date by `M.pick`.
---@param root string
---@param state {clients: vim.lsp.Client[]}
---@param scope_dir string?
---@return fun(opts: snacks.picker.lsp.symbols.Config, ctx: snacks.picker.finder.ctx): fun(cb: async fun(item: snacks.picker.finder.Item))
local function workspace_symbols_finder(root, state, scope_dir)
    ---@param opts snacks.picker.lsp.symbols.Config
    ---@param ctx snacks.picker.finder.ctx
    return function(opts, ctx)
        if opts.keep_parents then
            ctx.picker.matcher.opts.keep_parents = true
            ctx.picker.matcher.opts.sort = false
        end

        local filters = opts.filter or {}
        local query = ctx.filter.search or ''

        ---@async
        ---@param cb async fun(item: snacks.picker.finder.Item)
        return function(cb)
            local lsp_source = require('snacks.picker.source.lsp')
            local items = {} ---@type snacks.picker.finder.Item[]

            for _, client in ipairs(state.clients) do
                local filter = kind_filter(filters, client)
                ---@diagnostic disable-next-line: param-type-mismatch
                lsp_source.request(client, 'workspace/symbol', function()
                    return { query = query }
                end, function(request_client, result)
                    local client_items =
                        lsp_source.results_to_items(request_client, result, {
                            text_with_file = true,
                            filter = function(item)
                                if type(filter) == 'boolean' then
                                    return filter
                                end
                                local kind = item.kind
                                    and lsp_source.symbol_kind(item.kind)
                                    or 'Unknown'
                                return vim.list_contains(filter, kind)
                            end,
                        })
                    vim.list_extend(items, client_items)
                end)
            end

            local effective_scope = scope_dir or root
            items = vim.tbl_filter(function(item)
                return in_scope(item.file, effective_scope)
            end, items)

            items = require('conf.snacks.fuzzy').rank_items(items, query, nil, function(item)
                return item.name or item.text or ''
            end)

            for _, item in ipairs(items) do
                item.tree = opts.tree
                ---@diagnostic disable-next-line: await-in-sync
                cb(item)
            end
        end
    end
end

--- Refresh the picker once all `ids` are initialized (or after a timeout).
---@param picker snacks.Picker
---@param ids integer[]
---@param on_ready fun()
local function when_initialized(picker, ids, on_ready)
    local deadline = vim.uv.now() + 10000
    local function poll()
        if picker.closed then
            return
        end
        local ready = vim.iter(ids):all(function(id)
            local client = vim.lsp.get_client_by_id(id)
            return client == nil or client.initialized == true
        end)
        if ready or vim.uv.now() > deadline then
            on_ready()
        else
            vim.defer_fn(poll, 50)
        end
    end
    poll()
end

---@param opts? {search?:string, scope_dir?:string, client?:string}
---@return snacks.Picker?
function M.pick(opts)
    opts = opts or {}
    local root = vim.g.workspace_root or assert(vim.uv.cwd())
    local scope_dir = opts.scope_dir
    local only = opts.client
    local clients = project_clients(root, only)
    local state = { clients = clients }
    require('conf.fuzzy').preload()

    ---@param overrides {search?:string, scope_dir?:string|false, client?:string|false}
    ---@param picker snacks.Picker
    local function reopen(picker, overrides)
        local next_opts = {
            search = picker.input:get(),
            scope_dir = scope_dir,
            client = only,
        }
        for key, value in pairs(overrides) do
            next_opts[key] = value or nil
        end
        picker:close()
        M.pick(next_opts)
    end

    local picker = Snacks.picker.lsp_workspace_symbols({
        title = picker_title(clients, root, scope_dir),
        cwd = root,
        finder = workspace_symbols_finder(root, state, scope_dir),
        search = opts.search,
        matcher = {
            fuzzy = true,
            ignorecase = false,
            smartcase = true,
        },
        actions = {
            pick_scope_dir = function(self, _)
                ---@diagnostic disable-next-line: undefined-field
                Snacks.picker.dirs({
                    title = 'Pick Symbol Scope Directory',
                    cwd = root,
                    confirm = function(dir_picker, item)
                        if not item or not item.file then
                            return
                        end
                        dir_picker:close()
                        reopen(self, { scope_dir = vim.fs.joinpath(root, item.file) })
                    end,
                })
            end,
            clear_scope_dir = function(self, _)
                if scope_dir then
                    reopen(self, { scope_dir = false })
                end
            end,
            cycle_client = function(self, _)
                -- all -> each client name -> all
                local names = client_names(project_clients(root))
                if #names < 2 and not only then
                    return
                end
                -- position of the current client (0 = all, unknown name -> 0)
                local idx = only and vim.fn.index(names, only) + 1 or 0
                reopen(self, { client = names[idx + 1] or false })
            end,
        },
        win = {
            input = {
                keys = {
                    ['<C-d>'] = {
                        'pick_scope_dir',
                        mode = { 'i', 'n' },
                        desc = 'Pick symbol scope directory',
                    },
                    ['<C-b>'] = {
                        'clear_scope_dir',
                        mode = { 'i', 'n' },
                        desc = 'Clear symbol scope directory',
                    },
                    ['<C-l>'] = {
                        'cycle_client',
                        mode = { 'i', 'n' },
                        desc = 'Cycle LSP client (all/single)',
                    },
                },
            },
        },
        layout = {
            preset = 'dropdown',
            layout = { width = 0.5 },
        },
    })

    if not picker then
        return nil
    end

    if #clients == 0 then
        require('conf.workspace.lsp').start_project_clients(function(ids)
            if #ids == 0 then
                Snacks.notify.warn('No client supporting workspace symbols')
                picker:close()
                return
            end
            when_initialized(picker, ids, function()
                local current = project_clients(root, only)
                if #current == 0 then
                    Snacks.notify.warn('No client supporting workspace symbols')
                    picker:close()
                    return
                end
                state.clients = current
                picker.title = picker_title(current, root, scope_dir)
                picker:update_titles()
                picker:find({ refresh = true })
            end)
        end)
    end

    return picker
end

return M
