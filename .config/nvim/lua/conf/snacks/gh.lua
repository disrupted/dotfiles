local icons = require 'conf.icons'

local M = {}

---@class conf.snacks.gh.Filter
---@field key string lhs keymap
---@field icon string icon shown in the picker's `{flags}` title slot
---@field desc string human readable description used by keymaps
---@field qualifier string GitHub search qualifier, e.g. `author:@me`

---@class conf.snacks.gh.FilterGroup
---@field type 'pr' | 'issue'
---@field filters table<string, conf.snacks.gh.Filter>

-- Results are cached per repo + query so the list can be shown instantly on
-- reopen/toggle, then revalidated in the background (stale-while-revalidate).
---@type table<string, { time: number, items: snacks.picker.Item[] }>
local CACHE = {}
-- Freshly fetched results waiting to be swapped in by a follow-up find.
---@type table<string, snacks.picker.Item[]>
local PREFETCH = {}

-- Skip the background refetch when the cache is newer than this.
local REVALIDATE_AFTER = 5000

--- Builds the config fragment for a snacks GitHub picker source.
---
--- * `toggles` renders the active filter in the `{flags}` title slot and is
---   restored by `Snacks.picker.resume()`.
--- * `actions` are mutually exclusive `gh_toggle_<name>` actions (the stock
---   `toggle_<name>` actions only flip their own boolean).
--- * `finder` composes the active filter's GitHub search qualifier and fetches
---   through a small stale-while-revalidate cache. Typed text is deliberately
---   not sent to `gh`; with `live = false` it is matched locally by the snacks
---   matcher.
---@param spec conf.snacks.gh.FilterGroup
---@return snacks.picker.Config
function M.filters(spec)
    local names = vim.tbl_keys(spec.filters)
    table.sort(names) -- deterministic iteration order

    local toggles, actions = {}, {}
    local input_keys, list_keys = {}, {}
    for name, filter in pairs(spec.filters) do
        toggles[name] = { icon = filter.icon }
        input_keys[filter.key] = {
            'gh_toggle_' .. name,
            mode = { 'n', 'i' },
            desc = filter.desc,
        }
        list_keys[filter.key] = {
            'gh_toggle_' .. name,
            desc = filter.desc,
        }
        ---@param picker snacks.Picker
        actions['gh_toggle_' .. name] = function(picker)
            local enable = not picker.opts[name]
            for _, other in ipairs(names) do
                picker.opts[other] = (other == name and enable) or nil
            end
            picker.list:set_target()
            picker:find()
        end
    end

    ---@param o table
    ---@param ctx snacks.picker.finder.ctx
    ---@return string
    local function cache_key(o, ctx)
        return table.concat({
            spec.type,
            o.repo or ctx:git_root(),
            o.search or '',
            o.state or 'open',
            tostring(o.limit or ''),
        }, '\0')
    end

    ---@type snacks.picker.finder
    local finder = function(opts, ctx)
        local o = vim.tbl_extend('force', {}, opts, { type = spec.type })
        local query = {}
        for _, name in ipairs(names) do
            if o[name] then
                query[#query + 1] = spec.filters[name].qualifier
            end
        end
        o.search = #query > 0 and table.concat(query, ' ') or nil

        local key = cache_key(o, ctx)

        -- Freshly prefetched results are swapped in by a follow-up find. Doing
        -- it synchronously (a table result) means finder.items goes straight
        -- from the cached count to the fresh count, with no empty flash.
        local prefetched = PREFETCH[key]
        PREFETCH[key] = nil
        if prefetched then
            CACHE[key] = { time = vim.uv.now(), items = prefetched }
            return prefetched
        end

        ---@async
        return function(cb)
            local cached = CACHE[key]

            -- Serve the cache instantly. It stays in finder.items (and thus in
            -- the results counter) while we revalidate in the background.
            if cached then
                for _, item in ipairs(cached.items) do
                    -- Items are reused across pickers. Drop the matcher's
                    -- bookkeeping so a fresh matcher (tick 0) doesn't treat them
                    -- as already processed and skip them.
                    item.match_tick, item.match_topk = nil, nil
                    cb(item)
                end
                if vim.uv.now() - cached.time <= REVALIDATE_AFTER then
                    return
                end
                local fresh = {}
                local fetched = false
                require('snacks.gh.api')
                    .list(spec.type, function(received)
                        if not received then
                            return
                        end
                        fetched = true
                        vim.list_extend(fresh, received)
                    end, o)
                    :wait()
                if fetched then
                    PREFETCH[key] = fresh
                    local picker = ctx.picker
                    vim.schedule(function()
                        if not picker.closed then
                            picker:find { refresh = true }
                        end
                    end)
                end
                return
            end

            -- Cold path: nothing cached yet.
            local items = {}
            local ok = false
            require('snacks.gh.api')
                .list(spec.type, function(received)
                    if not received then
                        return
                    end
                    ok = true
                    for _, item in ipairs(received) do
                        items[#items + 1] = item
                        cb(item)
                    end
                end, o)
                :wait()
            if ok then
                CACHE[key] = { time = vim.uv.now(), items = items }
            end
        end
    end

    return {
        toggles = toggles,
        actions = actions,
        finder = finder,
        -- Typing filters the already-loaded list locally instead of refetching.
        live = false,
        supports_live = false,
        -- Show the picker (and its spinner) immediately instead of waiting for
        -- the first results, since `live = false` disables the instant-show path.
        show_delay = 0,
        win = {
            input = { keys = input_keys },
            list = { keys = list_keys },
        },
    }
end

---@type snacks.picker.Config
M.pr = M.filters {
    type = 'pr',
    filters = {
        mine = {
            key = '<A-a>',
            icon = icons.misc.user,
            desc = 'Authored or assigned to me',
            qualifier = 'involves:@me',
        },
        review_requested = {
            key = '<A-r>',
            icon = icons.git.review,
            desc = 'Review requested',
            qualifier = 'review-requested:@me',
        },
    },
}

---@type snacks.picker.Config
M.issue = M.filters {
    type = 'issue',
    filters = {
        assignee_me = {
            key = '<A-a>',
            icon = icons.misc.user,
            desc = 'Assigned to me',
            qualifier = 'assignee:@me',
        },
    },
}

return M
