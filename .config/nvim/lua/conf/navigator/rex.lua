---@class Rex: Vi
local Rex = require('Navigator.mux.vi'):new()

local directions = { h = 'left', j = 'down', k = 'up', l = 'right' }

function Rex:new()
    local session = vim.env.REX_SESSION
    assert(session, '[Navigator] Rex is not running!')

    local bin = vim.env.REX_BIN_DIR and (vim.env.REX_BIN_DIR .. '/rex') or 'rex'
    self.__index = self
    return setmetatable({ session = session, bin = bin }, self)
end

function Rex.zoomed()
    return false
end

---@param direction Direction
function Rex:navigate(direction)
    local dir = directions[direction]
    if dir then
        vim.system({ self.bin, 'focus', dir, '-s', self.session })
    end
    return self
end

return Rex
