local M = {}

function M.config()
    require('bqf').setup { preview = { auto_preview = false } }
    require('bqf').enable()
end

return M
