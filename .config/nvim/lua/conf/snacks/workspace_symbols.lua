local lsp_source = require 'snacks.picker.source.lsp'
local workspace_lsp = require 'conf.workspace.lsp'

local M = {}

---@param path string?
---@return string?
local function normalize(path)
    if not path or path == '' then
        return nil
    end
    return vim.fs.normalize(path)
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

    local config_root = normalize(client.config and client.config.root_dir)
    if config_root == root then
        return true
    end

    for _, folder in ipairs(client.workspace_folders or {}) do
        local folder_root = normalize(vim.uri_to_fname(folder.uri))
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
---@return snacks.picker.finder
local function workspace_symbols_finder(root, project_filetype, selected_client)
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
                local items =
                    lsp_source.results_to_items(request_client, result, {
                        text_with_file = true,
                        filter = function(item)
                            return want(lsp_source.symbol_kind(item.kind))
                        end,
                    })

                for _, item in ipairs(items) do
                    item.tree = opts.tree
                    cb(item)
                end
            end)
        end
    end
end

---@return snacks.Picker?
function M.pick()
    local root = normalize(vim.g.workspace_root)
    local project_filetype = vim.g.project_filetype
    local client = workspace_symbol_client(root, project_filetype)

    if not client then
        workspace_lsp.start_project_clients()
        client = workspace_symbol_client(root, project_filetype)
    end

    local title = 'LSP Workspace Symbols'
    if client then
        title = ('%s [%s]'):format(title, client.name)
    end

    local picker = Snacks.picker.lsp_workspace_symbols {
        title = title,
        finder = workspace_symbols_finder(root, project_filetype, client),
        matcher = {
            fuzzy = true,
            ignorecase = false,
            smartcase = true,
        },
        layout = {
            preset = 'dropdown',
            layout = { width = 0.5 },
        },
        actions = {
            toggle_live_match = function(self, _)
                if self.opts.live then
                    local search = self.input:get()
                    self.input:set(search)
                end
                self:action 'toggle_live'
            end,
        },
        win = {
            input = {
                keys = {
                    ['<C-g>'] = {
                        'toggle_live_match',
                        mode = { 'i', 'n' },
                        desc = 'Toggle live, apply live search as match pattern',
                    },
                },
            },
        },
    }

    if not picker then
        return nil
    end

    picker.input.win:on({ 'TextChangedI', 'TextChanged' }, function(win)
        if not win:valid() then
            return
        end
        if picker.opts.live then
            picker.input.filter.pattern = picker.input.filter.search
        end
    end, { buf = true })

    vim.defer_fn(function()
        local current_client = workspace_symbol_client(root, project_filetype)
        if not current_client then
            Snacks.notify.warn 'No client supporting workspace symbols'
            return
        end
        picker.title = ('LSP Workspace Symbols [%s]'):format(
            current_client.name
        )
        picker:update_titles()
    end, 1000)

    return picker
end

return M
