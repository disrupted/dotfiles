---@class overseer.SnacksStrategy : overseer.Strategy
---@field bufnr integer
---@field task nil|overseer.Task
local SnacksStrategy = {}

function SnacksStrategy.new(opts)
    opts = vim.tbl_extend('keep', opts or {}, {
        use_shell = false,
        size = nil,
        direction = nil,
        highlights = nil,
        auto_scroll = nil,
        close_on_exit = false,
        quit_on_exit = 'never',
        open_on_start = true,
        hidden = false,
        on_create = nil,
    })
    local strategy = {
        opts = opts,
        term = nil,
    }
    setmetatable(strategy, { __index = SnacksStrategy })
    ---@type overseer.SnacksStrategy
    return strategy
end

return SnacksStrategy
