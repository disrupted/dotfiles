local M = {}

function M.config()
  require('kommentary.config').config["lua"] = {"--", false}
end

return M
