---@diagnostic disable: undefined-global

return {
    s({ -- from akinsho
        trig = 'use',
        name = 'packer use',
        dscr = {
            'packer use plugin block',
            'e.g.',
            'use {\'author/plugin\'}',
        },
    }, {
        t 'use { \'',
        -- Get the author and URL in the clipboard and auto populate the author and project
        f(function(_)
            local default = 'author/plugin'
            local clip = vim.fn.getreg '*'
            if not vim.startswith(clip, 'https://github.com/') then
                return default
            end
            local parts = vim.split(clip, '/')
            if #parts < 2 then
                return default
            end
            local author, project = parts[#parts - 1], parts[#parts]
            return author .. '/' .. project
        end, {}),
        t '\' ',
        i(2, { ', config = function()', '', 'end' }),
        t '}',
    }),
}
