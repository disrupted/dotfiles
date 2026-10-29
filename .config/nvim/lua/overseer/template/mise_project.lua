--- mise tasks of the whole project, replacing overseer's builtin mise provider.
---
--- In a monorepo this includes the tasks of every config root (e.g. `//backend:test`).
--- Tasks run from the workspace root. Usage specs (flags, args) become overseer
--- params, resolved lazily when a task is built.

---@class mise.UsageArg
---@field name string
---@field help? string
---@field required? boolean
---@field var? boolean
---@field default? string[]
---@field choices? {choices: string[]}

---@class mise.UsageFlag
---@field name string
---@field help? string
---@field long string[]
---@field short string[]
---@field default? string[]
---@field negate? string
---@field arg? mise.UsageArg

---@class mise.UsageCmd
---@field flags mise.UsageFlag[]
---@field args mise.UsageArg[]

---@type table<string, mise.UsageCmd|false> "<root>\0<task>" -> parsed usage
local usage_cache = {}

---@param root string
---@param name string
---@return mise.UsageCmd?
local function usage_spec(root, name)
    local key = root .. '\0' .. name
    if usage_cache[key] == nil then
        local out = vim.system(
            { 'mise', 'tasks', 'info', name, '--json' },
            { cwd = root, text = true }
        ):wait(5000)
        local ok, info = pcall(vim.json.decode, out.stdout or '')
        local cmd = ok
            and type(info) == 'table'
            and info.usage_spec
            and info.usage_spec.cmd
        usage_cache[key] = cmd or false
    end
    return usage_cache[key] or nil
end

---@param flag mise.UsageFlag
---@return string
local function flag_switch(flag)
    if flag.long[1] then
        return '--' .. flag.long[1]
    end
    return '-' .. flag.short[1]
end

---@param flag mise.UsageFlag
---@return boolean
local function bool_default(flag)
    return flag.default ~= nil and flag.default[1] == 'true'
end

---@param spec mise.UsageCmd
---@return overseer.Params
local function to_params(spec)
    local params = {} ---@type overseer.Params
    for _, flag in ipairs(spec.flags or {}) do
        if flag.arg then
            local choices = flag.arg.choices and flag.arg.choices.choices
            local default = flag.default and flag.default[1] or nil
            if choices then
                params[flag.name] = {
                    type = 'enum',
                    choices = choices,
                    default = default,
                    desc = flag.help,
                    optional = true,
                } --[[@as overseer.EnumParam]]
            else
                params[flag.name] = {
                    type = 'string',
                    default = default,
                    desc = flag.help,
                    optional = true,
                } --[[@as overseer.StringParam]]
            end
        else
            params[flag.name] = {
                type = 'boolean',
                default = bool_default(flag),
                desc = flag.help,
                optional = true,
            }
        end
    end
    for _, arg in ipairs(spec.args or {}) do
        local default = arg.default and arg.default[1] or nil
        params[arg.name] = {
            type = 'string',
            default = default,
            desc = arg.help,
            -- required args without default make overseer open its form
            optional = not arg.required or default ~= nil,
        }
    end
    return params
end

---@param name string
---@param spec mise.UsageCmd?
---@param params table
---@return string[]
local function to_cmd(name, spec, params)
    local cmd = { 'mise', 'run', name }
    if not spec then
        return cmd
    end
    for _, flag in ipairs(spec.flags or {}) do
        local value = params[flag.name]
        if flag.arg then
            if value ~= nil and value ~= '' then
                vim.list_extend(cmd, { flag_switch(flag), value })
            end
        elseif value and not bool_default(flag) then
            table.insert(cmd, flag_switch(flag))
        elseif value == false and bool_default(flag) and flag.negate then
            table.insert(cmd, flag.negate)
        end
    end
    for _, arg in ipairs(spec.args or {}) do
        local value = params[arg.name]
        if type(value) == 'string' and value ~= '' then
            if arg.var then
                vim.list_extend(cmd, vim.split(value, '%s+', { trimempty = true }))
            else
                table.insert(cmd, value)
            end
        end
    end
    return cmd
end

---@param opts overseer.SearchParams
---@return string
local function project_root(opts)
    return vim.g.workspace_root or opts.dir
end

local group = vim.api.nvim_create_augroup('overseer.mise_project', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    pattern = { 'mise.toml', '.mise.toml', 'mise.*.toml', '.mise.*.toml' },
    desc = 'Refresh mise tasks of the project',
    callback = function()
        usage_cache = {}
        require('overseer.template').clear_cache({ dir = vim.g.workspace_root or '' })
    end,
})

---@type overseer.TemplateFileProvider
return {
    cache_key = project_root,
    condition = {
        callback = function()
            return vim.fn.executable('mise') == 1, 'Command "mise" not found'
        end,
    },
    generator = function(opts, cb)
        local root = project_root(opts)
        require('overseer').builtin.system(
            { 'mise', 'tasks', 'ls', '--all', '--local', '--json' },
            { cwd = root, text = true },
            vim.schedule_wrap(function(out)
                if out.code ~= 0 then
                    cb(vim.trim(out.stderr or 'mise tasks ls failed'))
                    return
                end
                local ok, tasks = pcall(vim.json.decode, out.stdout or '', {
                    luanil = { object = true },
                })
                if not ok or type(tasks) ~= 'table' then
                    cb('failed to parse mise tasks: ' .. tostring(tasks))
                    return
                end
                local ret = {} ---@type overseer.TemplateFileDefinition[]
                for _, task in ipairs(tasks) do
                    if not task.hide then
                        local has_usage = type(task.usage) == 'string'
                            and task.usage ~= ''
                        ret[#ret + 1] = {
                            name = 'mise ' .. task.name,
                            desc = task.description ~= '' and task.description or nil,
                            params = has_usage
                                    and function()
                                        local spec = usage_spec(root, task.name)
                                        return spec and to_params(spec) or {}
                                    end
                                or nil,
                            builder = function(params)
                                local spec = has_usage and usage_spec(root, task.name)
                                    or nil
                                ---@type overseer.TaskDefinition
                                return {
                                    cmd = to_cmd(task.name, spec, params),
                                    cwd = root,
                                }
                            end,
                        }
                    end
                end
                cb(ret)
            end)
        )
    end,
}
