---@meta

---@class doze.KeySpec: vim.keymap.set.Opts
---@field [1] string lhs
---@field [2]? string|fun() rhs; omit it when the plugin maps lhs itself
---@field mode? string|string[]

---@alias doze.Event vim.api.keyset.events|'VeryLazy'

---@class doze.Spec
---@field src string
---@field name? string
---@field version? string|vim.VersionRange
---@field data? any
---@field lazy? boolean
---@field enabled? boolean installed either way; `false` only keeps it from loading
---@field priority? integer
---@field dependencies? string[] names of other specs, loaded first
---@field event? doze.Event|doze.Event[]
---@field ft? string|string[]
---@field cmd? string|string[]
---@field keys? doze.KeySpec[]
---@field main? string
---@field opts? table passed to `require(main).setup()`
---@field init? fun(plugin: doze.Plugin)
---@field config? fun(plugin: doze.Plugin)
---@field build? string|fun(plugin: doze.Plugin)

---@class doze.Plugin
---@field name string
---@field path string
---@field spec doze.Spec
---@field state? 'loading'|'loaded'
