local M = {}

local backend = nil
local backend_error = nil
local backend_loaded = false
local warned = false

---@param msg string
local function warn_once(msg)
    if warned then
        return
    end
    warned = true
    vim.notify(msg, vim.log.levels.WARN)
end

---@return table?, string?
local function get_backend()
    if backend_loaded then
        return backend, backend_error
    end

    backend_loaded = true
    local ok, mod = pcall(require, 'frizbee')
    if ok then
        backend = mod
        return backend, nil
    end

    backend_error = mod
    return nil, backend_error
end

---@param query string
---@return boolean
local function has_uppercase(query)
    return query:match '%u' ~= nil
end

---@param text string
---@param query string
---@param case_sensitive boolean
---@return boolean
local function is_subsequence(text, query, case_sensitive)
    if query == '' then
        return true
    end

    if not case_sensitive then
        text = text:lower()
        query = query:lower()
    end

    local qi = 1
    for i = 1, #text do
        if text:sub(i, i) == query:sub(qi, qi) then
            qi = qi + 1
            if qi > #query then
                return true
            end
        end
    end

    return false
end

---@param text string
---@param case_sensitive boolean
---@return string
local function normalize_case(text, case_sensitive)
    if case_sensitive then
        return text
    end
    return text:lower()
end

---@param text string
---@param query string
---@param case_sensitive boolean
---@return integer
local function match_tier(text, query, case_sensitive)
    if query == '' then
        return 3
    end

    local haystack = normalize_case(text, case_sensitive)
    local needle = normalize_case(query, case_sensitive)

    if haystack == needle then
        return 0
    end

    local start_col = haystack:find(needle, 1, true)
    if start_col == 1 then
        return 1
    end
    if start_col ~= nil then
        return 2
    end

    return 3
end

---@param matches table[]
---@param query string
---@param candidates {key:string,text:string}[]
---@param case_sensitive boolean
---@return table[]
local function post_rank(matches, query, candidates, case_sensitive)
    local query_len = #query
    for order, match in ipairs(matches) do
        local idx = tonumber(match.key)
        local text = idx and candidates[idx] and candidates[idx].text or ''
        match._tier = match_tier(text, query, case_sensitive)
        match._len = #text
        match._dist = math.abs(match._len - query_len)
        match._order = order
    end

    table.sort(matches, function(a, b)
        if a._tier ~= b._tier then
            return a._tier < b._tier
        end
        if a._tier <= 2 and a._dist ~= b._dist then
            return a._dist < b._dist
        end
        if a.score ~= b.score then
            return a.score > b.score
        end
        if a._len ~= b._len then
            return a._len < b._len
        end
        return a._order < b._order
    end)

    for _, match in ipairs(matches) do
        match._tier = nil
        match._len = nil
        match._dist = nil
        match._order = nil
    end

    return matches
end

---@param candidates {key:string,text:string}[]
---@param query string
---@param case_sensitive boolean
---@param strict_smartcase boolean
---@return {key:string,score:number}[]
local function fallback_match(
    candidates,
    query,
    case_sensitive,
    strict_smartcase
)
    local matches = {}

    for index, candidate in ipairs(candidates) do
        local text = candidate.text or ''
        local matches_query = is_subsequence(text, query, case_sensitive)
        if matches_query then
            local score = query == '' and 0 or (1000 - #text + #query)
            matches[#matches + 1] = {
                key = candidate.key,
                score = score,
                _index = index,
            }
        end
    end

    table.sort(matches, function(a, b)
        if a.score ~= b.score then
            return a.score > b.score
        end
        return a._index < b._index
    end)

    for _, match in ipairs(matches) do
        match._index = nil
    end

    if strict_smartcase and has_uppercase(query) then
        local filtered = {}
        for _, match in ipairs(matches) do
            local idx = tonumber(match.key)
            local text = idx and candidates[idx] and candidates[idx].text or ''
            if is_subsequence(text, query, true) then
                filtered[#filtered + 1] = match
            end
        end
        return post_rank(filtered, query, candidates, case_sensitive)
    end

    return post_rank(matches, query, candidates, case_sensitive)
end

---@param query string
---@param candidates {key:string,text:string,payload?:any}[]
---@param opts? {smartcase?:boolean,strict_smartcase?:boolean,max_typos?:integer,limit?:integer,with_positions?:boolean,case_sensitive?:boolean}
---@return {key:string,score:number,positions?:integer[]}[]
function M.match(query, candidates, opts)
    opts = vim.tbl_deep_extend('force', {
        smartcase = true,
        strict_smartcase = true,
        with_positions = false,
    }, opts or {})

    local strict_smartcase = opts.strict_smartcase ~= false
    local case_sensitive = opts.case_sensitive
    if case_sensitive == nil then
        case_sensitive = opts.smartcase ~= false and has_uppercase(query)
    end

    local mod, err = get_backend()
    if not mod then
        warn_once(
            ('frizbee backend unavailable, using fallback matcher (%s)'):format(
                err
            )
        )
        local fallback =
            fallback_match(candidates, query, case_sensitive, strict_smartcase)
        if opts.limit and opts.limit > 0 and #fallback > opts.limit then
            return vim.list_slice(fallback, 1, opts.limit)
        end
        return fallback
    end

    local texts = {}
    for _, candidate in ipairs(candidates) do
        texts[#texts + 1] = candidate.text or ''
    end

    local ok, native = pcall(mod.match, query, texts, {
        max_typos = opts.max_typos,
        limit = opts.limit,
        with_positions = opts.with_positions,
        case_sensitive = case_sensitive,
    })

    if not ok then
        warn_once(
            ('frizbee match failed, using fallback matcher (%s)'):format(native)
        )
        return fallback_match(
            candidates,
            query,
            case_sensitive,
            strict_smartcase
        )
    end

    local matches = {}
    for _, item in ipairs(native or {}) do
        local index = item.index
        local candidate = candidates[index]
        if candidate then
            local keep = true
            if strict_smartcase and has_uppercase(query) then
                keep = is_subsequence(candidate.text or '', query, true)
            end
            if keep then
                matches[#matches + 1] = {
                    key = candidate.key,
                    score = item.score or 0,
                    positions = item.positions,
                }
            end
        end
    end

    matches = post_rank(matches, query, candidates, case_sensitive)
    if opts.limit and opts.limit > 0 and #matches > opts.limit then
        return vim.list_slice(matches, 1, opts.limit)
    end
    return matches
end

---@return table
function M.health()
    local mod, err = get_backend()
    if not mod then
        return {
            ok = false,
            backend = 'frizbee',
            error = err,
        }
    end

    local ok, info = pcall(mod.health)
    if not ok then
        return {
            ok = false,
            backend = 'frizbee',
            error = info,
        }
    end

    return {
        ok = true,
        backend = 'frizbee',
        info = info,
    }
end

return M
