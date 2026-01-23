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
            and vim.fn.executable(config.cmd[1]) == 1
        then
            table.insert(configs, config)
        end
    end
    return configs
end

--- Create a floating window using snacks.win
---@param options snacks.win.Config
---@param lines string[]
---@return snacks.win
vim.ui.float = function(options, lines)
    local snacks = require 'snacks'

    ---@param self snacks.win
    local on_buf = function(self)
        vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
    end

    return snacks.win.new(vim.tbl_deep_extend('force', {
        border = 'single',
        relative = 'editor',
        style = 'minimal',
        height = 0.75,
        width = 0.8,
        wo = { wrap = true },
    }, options or {}, { on_buf = on_buf }))
end

M.info = function()
    ---@param client vim.lsp.Client
    ---@param config vim.lsp.Config
    ---@return string
    local function client_command(client, config)
        local cmd = config.cmd or client.config.cmd

        if type(cmd) == 'table' then
            return table.concat(cmd, ' ')
        elseif type(cmd) == 'function' then
            --
            local info = debug.getinfo(cmd, 'S')

            return ('<function %s:%s>'):format(info.source, info.linedefined)
        else
            return tostring(config.cmd)
        end
    end

    ---@param word string
    ---@param items table
    ---@return string
    local function pluralize(word, items)
        return #items == 1 and word or word .. 's'
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients { bufnr = bufnr }

    local lines = {
        'Language Server Log: ' .. vim.lsp.get_log_path(),
        'Detected filetype  : ' .. vim.bo[bufnr].filetype,
        '',
        string.format(
            '%s %s attached to this buffer:',
            tostring(#clients),
            pluralize('client', clients)
        ),
    }

    for _, client in ipairs(clients) do
        ---@type vim.lsp.Config
        local config = vim.lsp.config[client.name] or {}

        local buffers =
            vim.iter(pairs(client.attached_buffers)):map(tostring):join ', '

        vim.list_extend(lines, {
            '',
            string.format(
                '%s (id: %s) %s: %s',
                client.name,
                client.id,
                pluralize('buffer', client.attached_buffers),
                buffers
            ),
            '',
            '  - command: ' .. client_command(client, config),
        })

        if client.workspace_folders and #client.workspace_folders > 1 then
            --
            vim.list_extend(lines, {
                '  - paths  : ',
            })

            for _, dir in ipairs(client.workspace_folders) do
                vim.list_extend(lines, { '            -' .. dir.name })
            end
        elseif client.root_dir then
            --
            vim.list_extend(lines, {
                '  - path   : ' .. vim.fn.fnamemodify(client.root_dir, ':~'),
            })
        end

        if config.filetypes then
            vim.list_extend(
                lines,
                { '  - types  : ' .. table.concat(config.filetypes, ', ') }
            )
        end
    end

    vim.ui.float({ ft = 'markdown', relative = 'editor' }, lines):show()
end

return M
