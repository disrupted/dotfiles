---@type doze.Spec
return {
    -- 'kevinhwang91/nvim-bqf',
    src = 'https://github.com/ofseed/nvim-bqf',
    version = 'native-open',
    ft = 'qf',
    config = function()
        ---@type BqfConfig
        local opts = {
            auto_enable = true,
            auto_resize_height = true,
            preview = {
                auto_preview = true,
                win_height = 12,
                win_vheight = 12,
                should_preview_cb = function(bufnr)
                    ---@diagnostic disable-next-line: param-type-mismatch
                    local fname = vim.api.nvim_buf_get_name(bufnr)
                    local stat = vim.uv.fs_stat(fname)
                    if not stat or stat.size > 100 * 1024 then
                        -- disable preview if file does not exist or size greater than 100k
                        -- TODO: still needed with async TreeSitter?
                        return false
                    end
                    return true
                end,
            },
        }
        require('bqf').setup(opts)
    end,
}
