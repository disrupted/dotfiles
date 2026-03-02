local M = {}

---source: dropbar.nvim
---Check if cursor is in range
---@param cursor integer[] cursor position (row, col) tuple; (1, 0)-based
---@param range lsp_range_t 0-based range
---@return boolean
function M.cursor_in_range(cursor, range)
    local row, col = unpack(cursor)
    row = row - 1
    return (
        row > range.start.line
        or (row == range.start.line and col >= range.start.character)
    )
        and (
            row < range['end'].line
            or (row == range['end'].line and col <= range['end'].character)
        )
end

return M
