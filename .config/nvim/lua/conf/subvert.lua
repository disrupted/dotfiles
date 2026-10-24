-- Pure-Lua port of vim-abolish's substitution commands (:S / :Subvert).
local M = {}

local function lower(s)
    return vim.fn.tolower(s)
end

local function upper(s)
    return vim.fn.toupper(s)
end

-- Port of abolish.vim's s:camelcase()
local function camelcase(word)
    word = word:gsub('%-', '_')
    if not word:find('_', 1, true) and word:find('%l') then
        return (word:gsub('^.', function(c)
            return lower(c)
        end))
    end
    local chars = vim.fn.split(word, '\\zs')
    local out, i = {}, 1
    while i <= #chars do
        if chars[i] == '_' then
            if i < #chars then
                -- `\(_\)\=\(.\)` consumes both, so `__` becomes `_`
                out[#out + 1] = upper(chars[i + 1])
                i = i + 2
            else
                out[#out + 1] = '_'
                i = i + 1
            end
        else
            out[#out + 1] = lower(chars[i])
            i = i + 1
        end
    end
    return table.concat(out)
end

local function mixedcase(word)
    return (camelcase(word):gsub('^.', function(c)
        return upper(c)
    end))
end

local function expand_braces(dict)
    local expanded, again = {}, false
    for bad, good in pairs(dict) do
        local before, middle, after = bad:match('^(.-){(.-)}(.*)$')
        if before then
            ---@cast middle string
            again = true
            local vbefore, vmiddle, vafter = good:match('^(.-){(.-)}(.*)$')
            if not vbefore then
                vbefore, vmiddle, vafter = good, ',', ''
            end
            ---@cast vmiddle string
            local targets = middle == '' and { '' }
                or vim.split(middle, ',', { plain = true, keepempty = true })
            local replacements = vmiddle == '' and { '' }
                or vim.split(vmiddle, ',', { plain = true, keepempty = true })
            if #replacements == 1 and replacements[1] == '' then
                replacements = targets
            end
            for i, target in ipairs(targets) do
                expanded[before .. target .. after] = vbefore
                    .. replacements[((i - 1) % #replacements) + 1]
                    .. vafter
            end
        else
            expanded[bad] = good
        end
    end
    return again and expand_braces(expanded) or expanded
end

local function create_dictionary(bad, good, opts)
    local dict = {}
    for from, to in pairs(expand_braces({ [bad] = good })) do
        if opts.case then
            dict[mixedcase(from)] = mixedcase(to)
            dict[lower(from)] = lower(to)
            dict[upper(from)] = upper(to)
        end
        dict[from] = to
    end
    return dict
end

local function subesc(pattern)
    return (pattern:gsub('[][\\/.*+?~%%()&]', '\\%0'))
end

-- Longest first, so `child{ren,}` prefers "children" over "child@!".
local function sort_keys(a, b)
    if lower(a) == lower(b) then
        if a == b then
            return false
        end
        return a < b
    elseif #a == #b then
        return lower(a) < lower(b)
    end
    return #a > #b
end

local function build_pattern(dict, boundaries)
    local prefix, suffix = '', ''
    if boundaries == 2 then
        prefix, suffix = '<', '>'
    elseif boundaries == 1 then
        prefix = '%(<|_@<=|[[:lower:]]@<=[[:upper:]]@=)'
        suffix = '%(>|_@=|[[:lower:]]@<=[[:upper:]]@=)'
    end
    local keys = vim.tbl_keys(dict)
    table.sort(keys, sort_keys)
    local alternatives = vim.tbl_map(subesc, keys)
    return '\\v\\C'
        .. prefix
        .. '%('
        .. table.concat(alternatives, '|')
        .. ')'
        .. suffix
end

local function normalize_options(flags)
    flags = flags or ''
    local opts = {
        case = not flags:find('I', 1, true),
        flags = flags:gsub('[avIiw]', ''),
        boundaries = 0,
    }
    if flags:find('w', 1, true) then
        opts.boundaries = 2
    elseif flags:find('v', 1, true) then
        opts.boundaries = 1
    end
    return opts
end

-- Split on `separator`, honouring `\<separator>` escapes.
local function split_unescaped(str, separator)
    local parts, current, i = {}, {}, 1
    while i <= #str do
        local char = str:sub(i, i)
        if char == '\\' and str:sub(i + 1, i + 1) == separator then
            current[#current + 1] = separator
            i = i + 2
        elseif char == separator then
            parts[#parts + 1] = table.concat(current)
            current = {}
            i = i + 1
        else
            current[#current + 1] = char
            i = i + 1
        end
    end
    parts[#parts + 1] = table.concat(current)
    return parts
end

-- Accept both `:S/bad/good/flags` (any separator) and `:S bad good flags`.
local function parse_args(args)
    args = vim.trim(args or '')
    if args == '' then
        return nil
    end
    local first = args:sub(1, 1)
    if first:match('%w') then
        local parts = vim.split(args, '%s+')
        return parts[1], parts[2], parts[3]
    end
    local parts = split_unescaped(args, first)
    return parts[2], parts[3], parts[4]
end

-- The dictionary from the last :S, used by the \= replacement expression.
-- It lives in a module-local instead of _G; the module stays cached in
-- package.loaded, so `&` can still repeat the substitution afterwards.
local last_dict = {}

-- Called from :substitute's \= expression as
-- v:lua.require'conf.subvert'.lookup(), which avoids polluting _G.
function M.lookup()
    local matched = vim.fn.submatch(0)
    return last_dict[matched] or matched
end

local function subvert(opts)
    local bad, good, flags = parse_args(opts.args)
    if not bad then
        vim.notify('S: argument required', vim.log.levels.ERROR)
        return
    end
    if good == nil then
        vim.notify('S: replacement required', vim.log.levels.ERROR)
        return
    end

    local normalized = normalize_options(flags)
    local dict = create_dictionary(bad, good, normalized)
    local pattern = build_pattern(dict, normalized.boundaries)
    last_dict = dict

    local range
    if opts.range == 0 then
        -- Like :s, :S defaults to the current line; use :%S for the buffer.
        range = '.'
    elseif opts.range == 1 then
        range = tostring(opts.line1)
    else
        range = opts.line1 .. ',' .. opts.line2
    end

    -- The "n" (count) flag is incompatible with a \= replacement expression
    -- (E48), and it never modifies text anyway.
    local replacement = normalized.flags:find('n', 1, true) and ''
        or '\\=v:lua.require\'conf.subvert\'.lookup()'

    local command = range
        .. 's/'
        .. pattern
        .. '/'
        .. replacement
        .. '/'
        .. normalized.flags
    ---@diagnostic disable-next-line: param-type-mismatch
    local ok, err = pcall(vim.cmd, command)
    if not ok then
        vim.notify('S: ' .. tostring(err), vim.log.levels.ERROR)
    end
end

function M.setup()
    local command_opts = {
        nargs = 1,
        range = true,
        bang = true,
        desc = 'Subvert: case-preserving substitution with brace variants',
    }
    if vim.fn.exists(':S') ~= 2 then
        vim.api.nvim_create_user_command('S', subvert, command_opts)
    end
    vim.api.nvim_create_user_command('Subvert', subvert, command_opts)
end

return M
