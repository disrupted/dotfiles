local fuzzy = require 'conf.fuzzy'
local matcher = require 'snacks.picker.core.matcher'

local M = {}

---@param item table
---@return string
local function default_text(item)
    local filter = item.filter
    if type(filter) == 'table' and type(filter.text) == 'string' then
        return filter.text
    end
    if type(item.name) == 'string' then
        return item.name
    end
    if type(item.text) == 'string' then
        return item.text
    end
    if type(item.file) == 'string' then
        return item.file
    end
    return tostring(item)
end

---@param items table[]
---@param query string
---@param opts? {smartcase?:boolean,strict_smartcase?:boolean,max_typos?:integer,limit?:integer,with_positions?:boolean,case_sensitive?:boolean}
---@param text_fn? fun(item:table):string
---@return table[]
function M.rank_items(items, query, opts, text_fn)
    if query == '' then
        return items
    end

    local get_text = text_fn or default_text
    local candidates = {}
    local index_to_item = {}

    for index, item in ipairs(items) do
        candidates[#candidates + 1] = {
            key = tostring(index),
            text = get_text(item),
        }
        index_to_item[index] = item
    end

    local matches = fuzzy.match(query, candidates, opts)
    local ranked = {}

    for _, match in ipairs(matches) do
        local index = tonumber(match.key)
        local item = index and index_to_item[index] or nil
        if item then
            item.score = match.score
            item.score_add = (match.score or 0) - matcher.DEFAULT_SCORE
            ranked[#ranked + 1] = item
        end
    end

    return ranked
end

return M
