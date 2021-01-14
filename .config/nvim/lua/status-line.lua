local gl = require('galaxyline')
local utils = require('utils')

local gls = gl.section
gl.short_line_list = {'defx', 'packager', 'vista'}

-- Colors
-- local colors = {
--     bg = '#282a36',
--     fg = '#f8f8f2',
--     section_bg = '#38393f',
--     yellow = '#f1fa8c',
--     cyan = '#8be9fd',
--     green = '#50fa7b',
--     orange = '#ffb86c',
--     magenta = '#ff79c6',
--     blue = '#8be9fd',
--     red = '#ff5555'
-- }

local colors = {
    bg = '#282c34',
    fg = '#aab2bf',
    section_bg = '#38393f',
    blue = '#61afef',
    green = '#98c379',
    purple = '#c678dd',
    red1 = '#e06c75',
    orange = '#e5c07b',
    red2 = '#be5046',
    yellow = '#e5c07b',
    gray1 = '#5c6370',
    gray2 = '#2c323d',
    gray3 = '#3e4452',
    darkgrey = '#5c6370',
    middlegrey = '#848586'
}

-- Local helper functions
local buffer_not_empty = function() return not utils.is_buffer_empty() end

local checkwidth = function()
    return utils.has_width_gt(40) and buffer_not_empty()
end

local mode_color = function()
    local mode_colors = {
        n = colors.green,
        i = colors.blue,
        c = colors.green,
        V = colors.purple,
        [''] = colors.purple,
        v = colors.purple,
        R = colors.red1
    }

    if mode_colors[vim.fn.mode()] ~= nil then
        return mode_colors[vim.fn.mode()]
    else
        print(vim.fn.mode())
        return colors.purple
    end

    -- return mode_colors[vim.fn.mode()]
end

-- Left side
-- gls.left[1] = {
--     FirstElement = {
--         provider = function()
--             vim.api.nvim_command('hi GalaxyFirstElement guifg=' .. mode_color())
--             return '▋'
--         end,
--         highlight = {colors.blue, colors.section_bg}
--     }
-- }
gls.left[1] = {
    ViMode = {
        provider = function()
            local alias = {
                n = 'NORMAL',
                i = 'INSERT',
                c = 'COMMAND',
                V = 'VISUAL',
                [''] = 'VISUAL',
                v = 'VISUAL',
                R = 'REPLACE'
            }
            vim.api.nvim_command('hi GalaxyViMode guibg=' .. mode_color())
            if alias[vim.fn.mode()] ~= nil then
                return '  ' .. alias[vim.fn.mode()] .. ' '
            else
                return '  V-BLOCK '
            end
        end,
        highlight = {colors.bg, colors.bg, 'bold'},
        -- separator = "  ",
        separator = " ",
        separator_highlight = {colors.bg, colors.section_bg}
    }
}
gls.left[2] = {
    FileIcon = {
        provider = 'FileIcon',
        condition = buffer_not_empty,
        highlight = {
            require('galaxyline.provider_fileinfo').get_file_icon_color,
            colors.section_bg
        }
    }
}
gls.left[3] = {
    FileName = {
        provider = {'FileName'},
        condition = buffer_not_empty,
        highlight = {colors.fg, colors.section_bg},
        separator = "",
        separator_highlight = {colors.section_bg, colors.bg}
    }
}
gls.left[9] = {
    DiagnosticError = {
        provider = 'DiagnosticError',
        icon = '  ',
        highlight = {colors.red1, colors.bg}
    }
}
gls.left[10] = {
    Space = {
        provider = function() return ' ' end,
        highlight = {colors.section_bg, colors.bg}
    }
}
gls.left[11] = {
    DiagnosticWarn = {
        provider = 'DiagnosticWarn',
        icon = '  ',
        highlight = {colors.red1, colors.bg}
    }
}
gls.left[12] = {
    Space = {
        provider = function() return ' ' end,
        highlight = {colors.section_bg, colors.bg}
    }
}
gls.left[13] = {
    DiagnosticInfo = {
        provider = 'DiagnosticInfo',
        icon = '  ',
        highlight = {colors.blue, colors.section_bg},
        separator = ' ',
        separator_highlight = {colors.section_bg, colors.bg}
    }
}

-- Right side
-- gls.right[1] = {
--     FileFormat = {
--         provider = function() return ' ' .. vim.bo.filetype end,
--         highlight = {colors.fg, colors.section_bg},
--         separator = '',
--         separator_highlight = {colors.section_bg, colors.bg}
--     }
-- }
gls.right[1] = {
    DiffAdd = {
        provider = 'DiffAdd',
        condition = checkwidth,
        icon = '+',
        highlight = {colors.green, colors.bg}
    }
}
gls.right[2] = {
    DiffModified = {
        provider = 'DiffModified',
        condition = checkwidth,
        icon = '~',
        highlight = {colors.orange, colors.bg}
    }
}
gls.right[3] = {
    DiffRemove = {
        provider = 'DiffRemove',
        condition = checkwidth,
        icon = '-',
        highlight = {colors.red1, colors.bg}
    }
}
gls.left[4] = {
    Space = {
        provider = function() return ' ' end,
        highlight = {colors.section_bg, colors.bg}
    }
}
-- gls.right[5] = {
--     GitIcon = {
--         provider = function() return '  ' end,
--         condition = buffer_not_empty,
--         highlight = {colors.red2, colors.bg}
--     }
-- }
gls.right[6] = {
    GitBranch = {
        provider = 'GitBranch',
        condition = buffer_not_empty,
        highlight = {colors.middlegrey, colors.bg}
    }
}
-- gls.right[7] = {
--     LineInfo = {
--         provider = 'LineColumn',
--         highlight = {colors.fg, colors.section_bg},
--         -- separator = ' | ',
--         -- separator_highlight = {colors.bg, colors.section_bg}
--         separator = '',
--         separator_highlight = {colors.section_bg, colors.bg}
--     }
-- }

-- Short status line
gls.short_line_left[1] = {
    BufferType = {
        provider = 'FileTypeName',
        highlight = {colors.fg, colors.section_bg},
        separator = ' ',
        separator_highlight = {colors.section_bg, colors.bg}
    }
}

gls.short_line_right[1] = {
    BufferIcon = {
        provider = 'BufferIcon',
        highlight = {colors.yellow, colors.section_bg},
        separator = '',
        separator_highlight = {colors.section_bg, colors.bg}
    }
}

-- Force manual load so that nvim boots with a status line
gl.load_galaxyline()
