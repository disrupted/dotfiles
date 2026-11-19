local loader = require('doze.loader')

local M = {}

local group = vim.api.nvim_create_augroup('doze', { clear = true })

---@param names string[]
---@return boolean loaded_any
local function load_all(names)
    local loaded_any = false
    for _, name in ipairs(names) do
        local plugin = loader.plugins[name]
        if plugin and not plugin.state then
            loader.load(name)
            loaded_any = true
        end
    end
    return loaded_any
end

---@param names string[]
---@return boolean
local function all_loaded(names)
    for _, name in ipairs(names) do
        local plugin = loader.plugins[name]
        if plugin and not plugin.state then
            return false
        end
    end
    return true
end

-- A buffer that triggers on FileType also went through BufReadPre/BufReadPost before the plugin existed.
---@type table<string, vim.api.keyset.events>
local previous_event = { FileType = 'BufReadPost', BufReadPost = 'BufReadPre' }

---@param event vim.api.keyset.events
---@return table<string, true>
local function groups_of(event)
    local groups = {}
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = event })) do
        if autocmd.group_name then
            groups[autocmd.group_name] = true
        end
    end
    return groups
end

local replaying = {}

---@param event vim.api.keyset.events
---@param opts vim.api.keyset.exec_autocmds
local function exec(event, opts)
    if replaying[event] then
        return
    end
    replaying[event] = true
    opts.modeline = false
    local ok, err = pcall(vim.api.nvim_exec_autocmds, event, opts)
    replaying[event] = nil
    if not ok then
        loader.warn(tostring(err))
    end
end

-- Replays the event for the augroups the load added, so their handlers see the buffer that loaded the plugin
-- (lazy.nvim does the same). FileType replays to every group: its point is handing the buffer to ft handlers.
---@param event vim.api.keyset.events
---@param pattern? string|string[]
---@param names string[]
local function on_event(event, pattern, names)
    vim.api.nvim_create_autocmd(event, {
        group = group,
        pattern = pattern,
        once = true,
        callback = function(ev)
            local states = {}
            local data = ev.data
            local current = ev.event --[[@as vim.api.keyset.events?]]
            while current do
                table.insert(states, 1, {
                    event = current,
                    exclude = current ~= 'FileType' and groups_of(current) or nil,
                    data = data,
                })
                data = nil
                current = previous_event[current]
            end
            if not load_all(names) then
                return
            end
            -- User events match on their pattern, not on a buffer.
            local target = ev.event == 'User' and { pattern = ev.match }
                or { buffer = ev.buf }
            for _, state in ipairs(states) do
                if not state.exclude then
                    exec(
                        state.event,
                        vim.tbl_extend('force', target, { data = state.data })
                    )
                else
                    local done = {}
                    for _, autocmd in
                        ipairs(vim.api.nvim_get_autocmds({ event = state.event }))
                    do
                        local name = autocmd.group_name
                        if
                            name
                            and name ~= 'doze'
                            and not state.exclude[name]
                            and not done[name]
                        then
                            done[name] = true
                            exec(
                                state.event,
                                vim.tbl_extend(
                                    'force',
                                    target,
                                    { group = name, data = state.data }
                                )
                            )
                        end
                    end
                end
            end
        end,
    })
end

---@param name string
---@param names string[]
local function on_cmd(name, names)
    local function unstub()
        pcall(vim.api.nvim_del_user_command, name)
        load_all(names)
    end
    vim.api.nvim_create_user_command(name, function(ev)
        unstub()
        if vim.fn.exists(':' .. name) ~= 2 then
            local hint = vim.v.vim_did_init == 0
                    and ' (called from init.lua before plugins load)'
                or ''
            loader.warn(
                (':%s is not defined by %s%s'):format(
                    name,
                    table.concat(names, ', '),
                    hint
                )
            )
            return
        end
        ---@type vim.api.keyset.cmd
        local cmd = {
            cmd = name,
            bang = ev.bang or nil,
            mods = ev.smods,
            args = ev.fargs,
            count = ev.count >= 0 and ev.range == 0 and ev.count or nil,
        }
        if ev.range == 1 then
            cmd.range = { ev.line1 }
        elseif ev.range == 2 then
            cmd.range = { ev.line1, ev.line2 }
        end
        vim.cmd(cmd)
    end, {
        bang = true,
        range = true,
        nargs = '*',
        desc = 'doze: load ' .. table.concat(names, ', '),
        complete = function(_, line)
            unstub()
            return vim.fn.getcompletion(line, 'cmdline')
        end,
    })
end

---@param key doze.KeySpec
---@return string[] modes, vim.keymap.set.Opts opts
local function key_parts(key)
    local mode = key.mode or 'n'
    local modes = type(mode) == 'table' and mode or { mode }
    local opts = {}
    for k, v in pairs(key) do
        if type(k) == 'string' and k ~= 'mode' then
            opts[k] = v
        end
    end
    return modes, opts
end

---@param key doze.KeySpec
---@param names string[]
local function on_key(key, names)
    local lhs, rhs = key[1], key[2]
    local modes, opts = key_parts(key)
    if all_loaded(names) then
        if rhs then
            vim.keymap.set(modes, lhs, rhs, opts)
        end
        return
    end
    vim.keymap.set(modes, lhs, function()
        -- Before loading, so a map the plugin sets for lhs survives.
        for _, mode in ipairs(modes) do
            pcall(vim.keymap.del, mode, lhs)
        end
        load_all(names)
        if rhs then
            vim.keymap.set(modes, lhs, rhs, opts)
        end
        -- Inserted ahead of typeahead: appending would run keys typed after lhs first.
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes('<Ignore>' .. lhs, true, true, true),
            'i',
            false
        )
    end, { desc = opts.desc, nowait = opts.nowait, expr = true })
end

---@param value? string|string[]
---@return string[]
local function list(value)
    if value == nil then
        return {}
    end
    return type(value) == 'table' and value or { value }
end

---@param plugins doze.Plugin[]
function M.setup(plugins)
    ---@type table<string, { event: vim.api.keyset.events, pattern?: string[], names: string[] }>
    local events = {}
    ---@type table<string, string[]>
    local cmds = {}
    ---@param event vim.api.keyset.events
    ---@param pattern? string[]
    ---@param name string
    local function add_event(event, pattern, name)
        local id = event .. '|' .. table.concat(pattern or {}, ',')
        events[id] = events[id] or { event = event, pattern = pattern, names = {} }
        table.insert(events[id].names, name)
    end

    for _, plugin in ipairs(plugins) do
        if loader.enabled(plugin) and not plugin.state then
            for _, event in ipairs(list(plugin.spec.event)) do
                if event == 'VeryLazy' then
                    add_event('User', { 'VeryLazy' }, plugin.name)
                else
                    ---@cast event vim.api.keyset.events
                    add_event(event, nil, plugin.name)
                end
            end
            local fts = list(plugin.spec.ft)
            if #fts > 0 then
                add_event('FileType', fts, plugin.name)
            end
            for _, cmd in ipairs(list(plugin.spec.cmd)) do
                cmds[cmd] = cmds[cmd] or {}
                table.insert(cmds[cmd], plugin.name)
            end
        end
        if loader.enabled(plugin) then
            for _, key in ipairs(plugin.spec.keys or {}) do
                on_key(key, { plugin.name })
            end
        end
    end

    for _, e in pairs(events) do
        on_event(e.event, e.pattern, e.names)
    end
    for name, names in pairs(cmds) do
        on_cmd(name, names)
    end

    local function very_lazy()
        vim.schedule(function()
            vim.api.nvim_exec_autocmds(
                'User',
                { pattern = 'VeryLazy', modeline = false }
            )
        end)
    end
    if vim.v.vim_did_enter == 1 then
        very_lazy()
    else
        vim.api.nvim_create_autocmd(
            'VimEnter',
            { group = group, once = true, callback = very_lazy }
        )
    end
end

return M
