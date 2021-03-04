vim.cmd [[packadd galaxyline.nvim]]
local gl = require('galaxyline')
local utils = require('conf.utils')

local gls = gl.section
gl.short_line_list = {'defx', 'packager', 'vista', 'NvimTree'}

local colors = {
    bg = '#282c34',
    fg = '#aab2bf',
    section_bg = '#38393f',
    blue = '#61afef',
    green = '#98c379',
    purple = '#c678dd',
    orange = '#e5c07b',
    red1 = '#e06c75',
    red2 = '#be5046',
    yellow = '#e5c07b',
    gray1 = '#5c6370',
    gray2 = '#2c323d',
    gray3 = '#3e4452',
    darkgrey = '#5c6370',
    grey = '#848586',
    middlegrey = '#8791A5'
}

-- Local helper functions
local buffer_not_empty = function() return not utils.is_buffer_empty() end

local checkwidth = function()
    return utils.has_width_gt(35) and buffer_not_empty()
end

local function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value[1] == val then return true end
    end
    return false
end

local mode_color = function()
    local mode_colors = {
        [110] = colors.green,
        [105] = colors.blue,
        [99] = colors.green,
        [116] = colors.blue,
        [118] = colors.purple,
        [22] = colors.purple,
        [86] = colors.purple,
        [82] = colors.red1,
        [115] = colors.red1,
        [83] = colors.red1
    }

    mode_color = mode_colors[vim.fn.mode():byte()]
    if mode_color ~= nil then
        return mode_color
    else
        return colors.purple
    end
end

local function file_readonly()
    if vim.bo.filetype == 'help' then return '' end
    if vim.bo.readonly == true then return '  ' end
    return ''
end

local function get_current_file_name()
    local file = vim.fn.expand('%:t')
    if vim.fn.empty(file) == 1 then return '' end
    if string.len(file_readonly()) ~= 0 then return file .. file_readonly() end
    if vim.bo.modifiable then
        if vim.bo.modified then return file .. '  ' end
    end
    return file .. ' '
end

-- local function trailing_whitespace()
--     local trail = vim.fn.search('\\s$', 'nw')
--     if trail ~= 0 then
--         return '  '
--     else
--         return nil
--     end
-- end

-- local function tab_indent()
--     local tab = vim.fn.search('^\\t', 'nw')
--     if tab ~= 0 then
--         return ' → '
--     else
--         return nil
--     end
-- end

local function buffers_count()
    local buffers = {}
    for _, val in ipairs(vim.fn.range(1, vim.fn.bufnr('$'))) do
        if vim.fn.bufexists(val) == 1 and vim.fn.buflisted(val) == 1 then
            table.insert(buffers, val)
        end
    end
    return #buffers
end

-- Left side
gls.left[1] = {
    ViMode = {
        provider = function()
            local aliases = {
                [110] = 'NORMAL',
                [105] = 'INSERT',
                [99] = 'COMMAND',
                [116] = 'TERMINAL',
                [118] = 'VISUAL',
                [22] = 'V-BLOCK',
                [86] = 'V-LINE',
                [82] = 'REPLACE',
                [115] = 'SELECT',
                [83] = 'S-LINE'
            }
            vim.api.nvim_command('hi GalaxyViMode guibg=' .. mode_color())
            alias = aliases[vim.fn.mode():byte()]
            if alias ~= nil then
                if utils.has_width_gt(35) then
                    mode = alias
                else
                    mode = alias:sub(1, 1)
                end
            else
                mode = vim.fn.mode():byte()
            end
            return '  ' .. mode .. ' '
        end,
        highlight = {colors.bg, colors.bg, 'bold'}
    }
}
gls.left[2] = {
    FileIcon = {
        provider = {function() return '  ' end, 'FileIcon'},
        condition = buffer_not_empty,
        highlight = {
            require('galaxyline.provider_fileinfo').get_file_icon,
            colors.section_bg
        }
    }
}
gls.left[3] = {
    FileName = {
        provider = get_current_file_name,
        condition = buffer_not_empty,
        highlight = {colors.fg, colors.section_bg},
        separator = '',
        separator_highlight = {colors.section_bg, colors.bg}
    }
}
-- gls.left[4] = {
--     WhiteSpace = {
--         provider = trailing_whitespace,
--         condition = buffer_not_empty,
--         highlight = {colors.fg, colors.bg}
--     }
-- }
-- gls.left[5] = {
--     TabIndent = {
--         provider = tab_indent,
--         condition = buffer_not_empty,
--         highlight = {colors.fg, colors.bg}
--     }
-- }
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
        highlight = {colors.orange, colors.bg}
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
gls.right[4] = {
    Space = {
        provider = function() return ' ' end,
        highlight = {colors.section_bg, colors.bg}
    }
}
gls.right[5] = {
    GitIcon = {
        provider = function() return '  ' end,
        condition = buffer_not_empty and
            require('galaxyline.provider_vcs').check_git_workspace,
        highlight = {colors.middlegrey, colors.bg}
    }
}
gls.right[6] = {
    GitBranch = {
        provider = 'GitBranch',
        condition = buffer_not_empty,
        highlight = {colors.middlegrey, colors.bg}
    }
}
gls.right[7] = {
    PerCent = {
        provider = 'LinePercent',
        separator = '',
        separator_highlight = {colors.blue, colors.bg},
        highlight = {colors.gray2, colors.blue}
    }
}
-- gls.right[8] = {
--     ScrollBar = {
--         provider = 'ScrollBar',
--         highlight = {colors.purple, colors.section_bg}
--     }
-- }

-- Short status line
gls.short_line_left[1] = {
    FileIcon = {
        provider = {function() return '  ' end, 'FileIcon'},
        condition = function()
            return buffer_not_empty and
                       has_value(gl.short_line_list, vim.bo.filetype)
        end,
        highlight = {
            require('galaxyline.provider_fileinfo').get_file_icon,
            colors.section_bg
        }
    }
}
gls.short_line_left[2] = {
    FileName = {
        provider = get_current_file_name,
        condition = buffer_not_empty,
        highlight = {colors.fg, colors.section_bg},
        separator = '',
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
