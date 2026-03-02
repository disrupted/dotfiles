local lsp_source = require 'snacks.picker.source.lsp'
local picker_format = require 'snacks.picker.format'

local M = {}

local TYPE_NAME_COLUMN = 26

---@param item snacks.picker.Item
---@param picker snacks.Picker
---@return snacks.picker.Highlight[]
function M.format_lsp_symbol(item, picker)
    local ret = {} ---@type snacks.picker.Highlight[]
    local kind = item.lsp_kind or item.kind or 'Unknown'
    kind = picker.opts.icons.kinds[kind] and kind or 'Unknown'

    ret[#ret + 1] =
        { picker.opts.icons.kinds[kind], 'SnacksPickerIcon' .. kind }
    ret[#ret + 1] = { ' ' }

    local name = vim.trim((item.name or ''):gsub('\r?\n', ' '))
    name = name == '' and (item.detail or '') or name
    Snacks.picker.highlight.format(item, name, ret)

    local offset = Snacks.picker.highlight.offset(ret, { char_idx = true })
    local gap = math.max(1, TYPE_NAME_COLUMN - offset)
    ret[#ret + 1] = { Snacks.picker.util.align(' ', gap) }
    vim.list_extend(ret, picker_format.filename(item, picker))

    return ret
end

---@param method string
---@param ctx snacks.picker.finder.ctx
---@return fun(cb: async fun(item: snacks.picker.finder.Item))
local function type_hierarchy(method, ctx)
    local buf = ctx.filter.current_buf
    local win = ctx.filter.current_win
    local seen = {}

    ---@async
    ---@param cb async fun(item: snacks.picker.finder.Item)
    return function(cb)
        local prepared = {}

        lsp_source.request(
            buf,
            'textDocument/prepareTypeHierarchy',
            function(client)
                return vim.lsp.util.make_position_params(
                    win,
                    client.offset_encoding
                )
            end,
            function(client, result)
                for _, base_item in ipairs(result or {}) do
                    prepared[#prepared + 1] = {
                        client = client,
                        base_item = base_item,
                    }
                end
            end
        )

        for _, req in ipairs(prepared) do
            lsp_source.request(req.client, method, function()
                return { item = req.base_item }
            end, function(client, hierarchy_items)
                local items =
                    lsp_source.results_to_items(client, hierarchy_items or {}, {
                        default_uri = req.base_item.uri,
                    })

                for _, item in ipairs(items) do
                    local key = table.concat({
                        item.file or '',
                        tostring(item.pos and item.pos[1] or 0),
                        tostring(item.pos and item.pos[2] or 0),
                        item.name or '',
                    }, ':')
                    if not seen[key] then
                        seen[key] = true
                        cb(item)
                    end
                end
            end)
        end
    end
end

---@param opts snacks.picker.lsp.Config
---@param ctx snacks.picker.finder.ctx
---@type snacks.picker.finder
function M.supertypes(opts, ctx)
    return type_hierarchy('typeHierarchy/supertypes', ctx)
end

---@param opts snacks.picker.lsp.Config
---@param ctx snacks.picker.finder.ctx
---@type snacks.picker.finder
function M.subtypes(opts, ctx)
    return type_hierarchy('typeHierarchy/subtypes', ctx)
end

return M
