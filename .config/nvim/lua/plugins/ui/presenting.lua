---@type doze.Spec
return {
    -- 'sotte/presenting.nvim',
    src = 'https://github.com/gerazov/presenting.nvim',
    version = 'add_title_to_footer',
    cmd = 'Presenting',
    config = function()
        require('presenting').setup({})
    end,
}
