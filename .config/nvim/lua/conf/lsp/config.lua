local M = {}

---@class find_config.Opts
---@field filetype string

---@param opts find_config.Opts
---@return vim.lsp.Config[]
M.filter_enabled = function(opts)
    local configs = {}
    local enabled_configs = vim.tbl_keys(vim.lsp._enabled_configs)
    for _, name in ipairs(enabled_configs) do
        ---@type vim.lsp.Config
        local config = vim.lsp.config[name]
        if
            vim.iter(config.filetypes):any(function(filetype)
                return filetype == opts.filetype
            end)
        then
            table.insert(configs, config)
        end
    end
    return configs
end

return M
