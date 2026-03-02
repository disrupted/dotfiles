local lsp_source = require 'snacks.picker.source.lsp'

local M = {}

---@param item snacks.picker.finder.Item
---@return boolean
local function is_site_packages(item)
    return type(item.file) == 'string'
        and item.file:match 'site%-packages' ~= nil
end

---@param item snacks.picker.finder.Item
---@return integer, integer
local function line_col(item)
    local line = item.pos and item.pos[1] or 0
    local col = item.pos and item.pos[2] or math.huge
    return line, col
end

---@param opts snacks.picker.lsp.Config
---@param ctx snacks.picker.finder.ctx
---@type snacks.picker.finder
function M.definitions_filtered(opts, ctx)
    local base =
        lsp_source.get_locations('textDocument/definition', opts, ctx.filter)

    ---@async
    ---@param cb async fun(item: snacks.picker.finder.Item)
    return function(cb)
        local primary_by_key = {} ---@type table<string, snacks.picker.finder.Item>
        local primary_order = {} ---@type string[]
        local secondary = {} ---@type snacks.picker.finder.Item[]

        base(function(item)
            if is_site_packages(item) then
                secondary[#secondary + 1] = item
                return
            end

            local line, col = line_col(item)
            local key = (item.file or '') .. ':' .. line
            local current = primary_by_key[key]
            if not current then
                primary_by_key[key] = item
                primary_order[#primary_order + 1] = key
                return
            end

            local _, current_col = line_col(current)
            if col < current_col then
                primary_by_key[key] = item
            end
        end)

        if #primary_order == 0 then
            vim.tbl_map(cb, secondary)
            return
        end

        for _, key in ipairs(primary_order) do
            cb(primary_by_key[key])
        end
    end
end

return M
