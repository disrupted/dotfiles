-- Atlas.nvim integration with one.nvim.
--
-- Atlas ships hardcoded Catppuccin-ish hex colors for its own `Atlas*`
-- highlight groups. They are declared with `default = true`, so they can be
-- overridden, but a colorscheme change requires re-applying the overrides.
-- This module derives Atlas' semantic groups from Neovim/one.nvim groups and
-- re-applies them after Atlas' own ColorScheme handler.
local M = {}

---@class conf.atlas.Highlight
---@field fg string|nil
---@field bg string|nil
---@field sp string|nil
---@field bold boolean|nil
---@field italic boolean|nil
---@field underline boolean|nil
---@field strikethrough boolean|nil

---@param value integer|string|nil
---@return string|nil
local function to_hex(value)
    if type(value) == 'number' then
        return string.format('#%06x', value)
    end
    return value
end

---Resolve a highlight group, following links.
---@param name string
---@return conf.atlas.Highlight
local function resolved(name)
    local hl = vim.api.nvim_get_hl(0, {
        name = name,
        link = false,
        create = false,
    })
    return {
        fg = to_hex(hl.fg),
        bg = to_hex(hl.bg),
        sp = to_hex(hl.sp),
        bold = hl.bold,
        italic = hl.italic,
        underline = hl.underline,
        strikethrough = hl.strikethrough,
    }
end

---@param name string
---@param fallback string
---@return string
local function fg(name, fallback)
    return resolved(name).fg or fallback
end

---@param color string
---@return integer, integer, integer
local function channels(color)
    local hex = color:gsub('^#', '')
    return assert(tonumber(hex:sub(1, 2), 16)),
        assert(tonumber(hex:sub(3, 4), 16)),
        assert(tonumber(hex:sub(5, 6), 16))
end

---Blend `color` into `base`. Works for both light and dark backgrounds.
---@param base string
---@param color string
---@param alpha number
---@return string
local function blend(base, color, alpha)
    local br, bg, bb = channels(base)
    local cr, cg, cb = channels(color)

    local function mix(from, to)
        return math.floor(from + (to - from) * alpha + 0.5)
    end

    return string.format('#%02x%02x%02x', mix(br, cr), mix(bg, cg), mix(bb, cb))
end

---Pick a readable foreground for a solid background.
---@param color string
---@return string
local function contrast(color)
    local r, g, b = channels(color)
    local brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    return brightness > 0.55 and '#1c1e26' or '#ffffff'
end

---@param color string
---@return vim.api.keyset.highlight
local function solid(color)
    return { bg = color, fg = contrast(color), bold = true }
end

---A low-contrast chip that still works on light and dark backgrounds.
---@param color string
---@param base string
---@param alpha number|nil
---@return vim.api.keyset.highlight
local function tint(color, base, alpha)
    local bg = blend(base, color, alpha or 0.28)
    return { bg = bg, fg = contrast(bg), bold = true }
end

---@return table<string, vim.api.keyset.highlight>
local function atlas_highlights()
    local normal = resolved('Normal')
    local base = normal.bg or (vim.o.background == 'light' and '#ffffff' or '#000000')
    local fg_normal = normal.fg
        or (vim.o.background == 'light' and '#1c1e26' or '#cdd6f4')

    local muted = fg('NonText', fg('Comment', fg_normal))
    local border = fg('FloatBorder', muted)
    local title = fg('Title', fg_normal)
    local ok = fg('DiagnosticOk', fg('String', muted))
    local info = fg('DiagnosticInfo', fg('Function', muted))
    local warn = fg('DiagnosticWarn', fg('Type', muted))
    local err = fg('DiagnosticError', fg('ErrorMsg', muted))
    local note = fg('@comment.note', fg('Special', info))
    local accent = fg('@function', fg('Function', info))
    local keyword = fg('@keyword', fg('Statement', note))
    local constant = fg('@constant', fg('Constant', warn))
    local parameter = fg('@variable.parameter', keyword)
    local string_fg = fg('@string', fg('String', ok))
    local type_fg = fg('@type', fg('Type', warn))
    local special = fg('Special', note)

    local line_bg = resolved('Pmenu').bg
        or resolved('CursorLine').bg
        or blend(base, fg_normal, 0.06)
    local footer_bg = resolved('StatusLine').bg or line_bg

    local groups = {
        -- Shared UI
        AtlasCodeBackground = { bg = line_bg },
        AtlasTabInactive = { link = 'CursorLine' },
        AtlasColumnHeader = { fg = muted, bold = true },
        AtlasSectionHeader = { fg = title, bold = true, underline = true },
        AtlasBorder = { fg = border },
        AtlasTextMuted = { fg = muted },
        AtlasTextMutedStrikethrough = { fg = muted, strikethrough = true },
        AtlasTextPositive = { fg = ok },
        AtlasTextNote = { fg = note, bold = true },
        AtlasTextWarning = { fg = warn, bold = true },

        -- Provider themes (keep the brand hue, adapt to the background)
        AtlasGitHubTheme = tint(fg_normal, base, 0.16),
        AtlasGitLabTheme = tint('#fc6d26', base, 0.4),
        AtlasBitbucketTheme = tint('#2684ff', base, 0.4),
        AtlasJiraTheme = tint('#2684ff', base, 0.4),

        -- Chips
        AtlasChipActive = solid(info),
        AtlasRelatedChip = { bg = line_bg, fg = muted, bold = true },

        -- Issues and Jira fields
        AtlasIssueOpen = { fg = ok, bold = true },
        AtlasIssueClosed = { fg = keyword, bold = true },
        AtlasIssueOpenChip = tint(ok, base),
        AtlasIssueClosedChip = tint(keyword, base),
        AtlasJiraKey = { fg = accent, bold = true },
        AtlasJiraEpic = { link = 'AtlasLogWarn' },
        AtlasJiraChipStoryPoints = tint(err, base),
        AtlasJiraChipDueDate = { bg = line_bg, fg = muted, bold = true },
        AtlasJiraChipParent = { link = 'AtlasJiraTheme' },

        -- Pull requests
        AtlasPROpen = { fg = ok },
        AtlasPRMerged = { fg = info },
        AtlasPRDeclined = { fg = err },
        AtlasPRDraft = { fg = warn },
        AtlasPROpenChip = tint(ok, base),
        AtlasPRMergedChip = tint(info, base),
        AtlasPRDeclinedChip = tint(err, base),
        AtlasPRDraftChip = tint(warn, base),

        -- Logs
        AtlasLogInfo = { fg = info },
        AtlasLogWarn = { fg = warn },
        AtlasLogError = { fg = err },
        AtlasLogErrorLine = { fg = err, bg = blend(base, err, 0.15) },
        AtlasLogGroup = { fg = fg_normal, bg = line_bg, bold = true },
        AtlasLogCommand = { fg = accent },
        AtlasLogDebug = { link = 'AtlasTextMuted' },

        -- Footer / custom statusline
        AtlasFooterBackground = { bg = footer_bg },
        AtlasFooterText = { fg = muted, bg = footer_bg },
        AtlasFooterActive = { fg = fg_normal, bg = footer_bg, bold = true },
        AtlasFooterInfo = { fg = info, bg = footer_bg, bold = true },
        AtlasFooterNote = { fg = note, bg = footer_bg, bold = true },
        AtlasFooterWarning = { fg = warn, bg = footer_bg, bold = true },
        AtlasFooterError = { fg = err, bg = footer_bg, bold = true },
        AtlasFooterSuccess = { fg = ok, bg = footer_bg, bold = true },

        -- Atlas markdown inline code has its own hardcoded background.
        AtlasMarkdownInlineCode = { fg = constant, bg = line_bg },
    }

    -- Stable colors for mentions, authors, Jira statuses, ...
    local palette = {
        accent,
        keyword,
        ok,
        warn,
        info,
        string_fg,
        constant,
        type_fg,
        parameter,
        note,
        special,
    }
    for index, color in ipairs(palette) do
        groups[string.format('AtlasDynColor%02d', index)] = { fg = color }
        groups[string.format('AtlasDynBgColor%02d', index)] = tint(color, base)
    end

    return groups
end

function M.apply()
    for name, opts in pairs(atlas_highlights()) do
        vim.api.nvim_set_hl(0, name, opts)
    end
end

---Atlas pads its UI lines with spaces. With `list` + `listchars` enabled
---globally, those padding spaces render as `·` (and lines get a trailing
---cell). Disable listchars only in Atlas UI windows.
function M.window_options()
    local group = vim.api.nvim_create_augroup('AtlasWindowOptions', {
        clear = true,
    })

    vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
        group = group,
        callback = function(args)
            local buf = args.buf
            if not vim.api.nvim_buf_is_valid(buf) then
                return
            end

            local name = vim.api.nvim_buf_get_name(buf)
            local filetype = vim.bo[buf].filetype
            local is_atlas = name:match('^atlas://') or filetype:match('^atlas%-ui%.')
            if not is_atlas then
                return
            end

            local win = vim.api.nvim_get_current_win()
            if vim.api.nvim_win_get_buf(win) ~= buf then
                return
            end

            vim.wo[win].list = false
        end,
        desc = 'Hide listchars in Atlas UI windows',
    })
end

function M.setup()
    M.apply()

    -- Atlas registers its own ColorScheme autocmd during setup(). This one is
    -- registered afterwards, so it wins and keeps Atlas in sync with one.nvim.
    vim.api.nvim_create_autocmd('ColorScheme', {
        group = vim.api.nvim_create_augroup('AtlasOneHighlights', {
            clear = true,
        }),
        callback = M.apply,
        desc = 'Re-apply Atlas highlights after a colorscheme change',
    })

    M.window_options()
end

return M
