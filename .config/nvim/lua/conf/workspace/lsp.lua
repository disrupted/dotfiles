local M = {}

-- Start LSP client for workspace
---@param config vim.lsp.Config
---@return integer? client_id
local start = function(config)
    if
        vim.iter(vim.lsp.get_clients()):any(function(client)
            return client.name == config.name
        end)
    then
        -- client already exists, abort
        return
    end
    config = vim.deepcopy(config)
    if not config.root_dir then
        if
            config.root_markers ~= nil
            and not vim.tbl_isempty(config.root_markers)
        then
            config.root_dir =
                vim.fs.root(vim.g.workspace_root, config.root_markers)
        else
            config.root_dir = vim.g.workspace_root
        end
    end
    Snacks.notify.info(
        string.format('Starting %s', config.name),
        { title = 'LSP' }
    )
    return vim.lsp.start(config)
end

---@type table<string, fun():integer?>
local default_clients = {
    python = function()
        return start(vim.lsp.config.basedpyright)
    end,
    rust = function()
        return require('rustaceanvim.lsp').start()
    end,
}

---@type table<string, fun():integer|integer[]|nil>
local clients = setmetatable(default_clients, {
    ---@param key string filetype
    __index = function(_, key)
        return function()
            local configs = require('conf.lsp.config').filter_enabled {
                filetype = key,
            }
            local client_ids = {}
            for _, config in ipairs(configs) do
                local client_id = start(config)
                table.insert(client_ids, client_id)
            end
            return client_ids
        end
    end,
})

M.start = function(filetype)
    return clients[filetype]()
end

return M
