local M = {}

function M.config()
    require('bqf').setup { preview = { auto_preview = true } }
    require('bqf').enable()
end

return M
