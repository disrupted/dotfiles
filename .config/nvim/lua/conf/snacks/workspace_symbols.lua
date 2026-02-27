local lsp_source = require 'snacks.picker.source.lsp'
local snacks_fuzzy = require 'conf.snacks.fuzzy'
local workspace_lsp = require 'conf.workspace.lsp'

local M = {}

---@param root string?
---@param scope_dir string?
---@return string?
local function scope_label(root, scope_dir)
    if not scope_dir then
        return nil
    end
    if root then
        local rel = vim.fs.relpath(root, scope_dir)
        if rel then
            return rel == '.' and './' or (rel .. '/')
        end
    end
    return scope_dir
end

---@param client vim.lsp.Client?
---@param root string?
---@param scope_dir string?
---@return string
local function picker_title(client, root, scope_dir)
    local title = 'LSP Workspace Symbols'
    if client then
        title = ('%s [%s]'):format(title, client.name)
    end
    local label = scope_label(root, scope_dir)
    if label then
        title = ('%s [%s]'):format(title, label)
    end
    return title
end

---@param file string?
---@param scope_dir string?
---@param root string?
---@return boolean
local function in_scope(file, scope_dir, root)
    if not scope_dir then
        return true
    end
    if not file or file == '' then
        return false
    end
    if file == scope_dir then
        return true
    end

    if root then
        local rel_file = vim.fs.relpath(root, file)
        local rel_scope = vim.fs.relpath(root, scope_dir)
        if rel_file and rel_scope then
            if rel_file == rel_scope then
                return true
            end
            local rel_prefix = rel_scope
            if not rel_prefix:match '/$' then
                rel_prefix = rel_prefix .. '/'
            end
            if vim.startswith(rel_file, rel_prefix) then
                return true
            end
        end
    end

    local prefix = scope_dir
    if not prefix:match '/$' then
        prefix = prefix .. '/'
    end
    return vim.startswith(file, prefix)
end

---@param client vim.lsp.Client
---@return boolean
local function supports_workspace_symbols(client)
    local cap = client.server_capabilities
    return cap ~= nil and cap.workspaceSymbolProvider ~= nil
end

---@param client vim.lsp.Client
---@param root string?
---@return boolean
local function client_matches_root(client, root)
    if not root then
        return false
    end

    local config_root = client.config and client.config.root_dir
    if config_root == root then
        return true
    end

    for _, folder in ipairs(client.workspace_folders or {}) do
        local folder_root = vim.uri_to_fname(folder.uri)
        if folder_root == root then
            return true
        end
    end

    return false
end

---@param root string?
---@param filetype string?
---@return vim.lsp.Client?
local function workspace_symbol_client(root, filetype)
    local clients = vim.lsp.get_clients()
    local best_client = nil
    local best_score = -1

    for _, client in ipairs(clients) do
        if supports_workspace_symbols(client) then
            local score = 0
            if client_matches_root(client, root) then
                score = score + 2
            end
            if
                filetype
                and vim.list_contains(
                    client.config and client.config.filetypes or {},
                    filetype
                )
            then
                score = score + 1
            end

            if
                not best_client
                or score > best_score
                or (score == best_score and client.id < best_client.id)
            then
                best_client = client
                best_score = score
            end
        end
    end

    return best_client
end

---@param root string?
---@param project_filetype string?
---@param selected_client vim.lsp.Client?
---@param scope_dir string?
---@return snacks.picker.finder
local function workspace_symbols_finder(
    root,
    project_filetype,
    selected_client,
    scope_dir
)
    ---@param opts snacks.picker.lsp.symbols.Config
    ---@param ctx snacks.picker.finder.ctx
    return function(opts, ctx)
        if opts.keep_parents then
            ctx.picker.matcher.opts.keep_parents = true
            ctx.picker.matcher.opts.sort = false
        end

        local filters = opts.filter or {}
        local filter = project_filetype and filters[project_filetype] or nil
        if filter == nil then
            filter = filters.default or true
        end

        ---@param kind string?
        ---@return boolean
        local function want(kind)
            kind = kind or 'Unknown'
            return type(filter) == 'boolean' or vim.tbl_contains(filter, kind)
        end

        ---@async
        ---@param cb async fun(item: snacks.picker.finder.Item)
        return function(cb)
            selected_client = selected_client
                or workspace_symbol_client(root, project_filetype)
            if not selected_client then
                return
            end

            lsp_source.request(selected_client, 'workspace/symbol', function()
                return { query = ctx.filter.search }
            end, function(request_client, result)
                local query = ctx.filter.search
                local items =
                    lsp_source.results_to_items(request_client, result, {
                        text_with_file = true,
                        filter = function(item)
                            return want(lsp_source.symbol_kind(item.kind))
                        end,
                    })

                if scope_dir then
                    items = vim.tbl_filter(function(item)
                        return in_scope(item.file, scope_dir, root)
                    end, items)
                end

                items = snacks_fuzzy.rank_items(items, query, {
                    smartcase = true,
                    strict_smartcase = true,
                }, function(item)
                    return item.name or item.text or ''
                end)

                for _, item in ipairs(items) do
                    item.tree = opts.tree
                    cb(item)
                end
            end)
        end
    end
end

---@param opts? {search?:string,scope_dir?:string}
---@return snacks.Picker?
function M.pick(opts)
    opts = opts or {}
    local root = vim.g.workspace_root
    local project_filetype = vim.g.project_filetype
    local scope_dir = opts.scope_dir
    local client = workspace_symbol_client(root, project_filetype)

    if not client then
        workspace_lsp.start_project_clients()
    end

    local title = picker_title(client, root, scope_dir)

    local picker = Snacks.picker.lsp_workspace_symbols {
        title = title,
        finder = workspace_symbols_finder(
            root,
            project_filetype,
            client,
            scope_dir
        ),
        search = opts.search,
        matcher = {
            fuzzy = true,
            ignorecase = false,
            smartcase = true,
        },
        actions = {
            pick_scope_dir = function(self, _)
                local current_search = self.input:get()
                Snacks.picker.dirs {
                    title = 'Pick Symbol Scope Directory',
                    cwd = root or vim.uv.cwd(),
                    confirm = function(dir_picker, item)
                        if not item then
                            return
                        end

                        local dir = item.file
                        local cwd = root or item.cwd
                        if dir and cwd then
                            dir = vim.fs.joinpath(cwd, dir)
                        end
                        dir_picker:close()
                        self:close()
                        M.pick {
                            search = current_search,
                            scope_dir = dir,
                        }
                    end,
                }
            end,
            clear_scope_dir = function(self, _)
                if not scope_dir then
                    return
                end
                local current_search = self.input:get()
                self:close()
                M.pick {
                    search = current_search,
                }
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
                },
            },
        },
        layout = {
            preset = 'dropdown',
            layout = { width = 0.5 },
        },
    }

    if not picker then
        return nil
    end

    if not client then
        vim.defer_fn(function()
            local current_client =
                workspace_symbol_client(root, project_filetype)
            if not current_client then
                Snacks.notify.warn 'No client supporting workspace symbols'
                return
            end
            picker.title = picker_title(current_client, root, scope_dir)
            picker:update_titles()
        end, 500)
    end

    return picker
end

return M
