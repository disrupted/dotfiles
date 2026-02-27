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
    return vim.lsp.start(config, { attach = false })
end

---@type table<string, fun():integer?>
local default_clients = {
    python = function()
        local configs = {
            vim.lsp.config.ty,
            vim.lsp.config.pyrefly,
            vim.lsp.config.basedpyright,
            vim.lsp.config.pyright,
        }
        -- check which server is available in venv
        local venv_path = vim.env.VIRTUAL_ENV
        for _, config in ipairs(configs) do
            local exepath = vim.fn.exepath(config.cmd[1])
            if exepath ~= '' then
                if vim.fs.relpath(venv_path, exepath) then
                    return start(config)
                end
            end
        end
    end,
    rust = function()
        require('rustaceanvim.lsp').start()
        config = vim.tbl_extend(
            'keep',
            vim.lsp.config['rust-analyzer'],
            { cmd = { 'rust-analyzer' } }
        )
        return start(config)
    end,
}

---@type table<string, fun():integer|integer[]|nil>
local clients = setmetatable(default_clients, {
    ---@param key string filetype
    ---@return integer[] client_ids
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

---@return integer[] started_client_ids
M.start_project_clients = function()
    local workspace = require 'conf.workspace'
    local filetypes = workspace.project_filetypes { buffers = false }
    local started = {}

    for _, filetype in ipairs(filetypes) do
        local client_ids = M.start(filetype)
        if type(client_ids) == 'number' then
            table.insert(started, client_ids)
        elseif type(client_ids) == 'table' then
            for _, id in ipairs(client_ids) do
                if id then
                    table.insert(started, id)
                end
            end
        end
    end

    return started
end

return M
