-- https://gist.github.com/MunifTanjim/8d9498c096719bdf4234321230fe3dc7
local Input = require('nui.input')
local event = require('nui.utils.autocmd').event

--- Converts an LSP column (in `encoding` units) to a byte index in `line`.
---@param line string
---@param col integer
---@param encoding 'utf-8'|'utf-16'|'utf-32'
---@return integer
local function lsp_col_to_byte(line, col, encoding)
    return vim.str_byteindex(line, encoding, col, false)
end

--- Returns the text of a single-line LSP range.
---@param bufnr integer
---@param range lsp.Range
---@param encoding 'utf-8'|'utf-16'|'utf-32'
---@return string?
local function text_at_range(bufnr, range, encoding)
    local line = vim.api.nvim_buf_get_lines(
        bufnr,
        range.start.line,
        range.start.line + 1,
        false
    )[1]
    if not line then
        return nil
    end
    local s = lsp_col_to_byte(line, range.start.character, encoding)
    local e = lsp_col_to_byte(line, range['end'].character, encoding)
    return line:sub(s + 1, e)
end

--- Notification listing the files touched by the rename.
---@param result lsp.WorkspaceEdit
---@param curr_name string
---@param new_name string
local function notify_renamed(result, curr_name, new_name)
    if not result.documentChanges or vim.tbl_isempty(result.documentChanges) then
        return
    end

    local msg = {
        ('**Renamed `%s` -> `%s`**'):format(curr_name, new_name),
        '', -- empty line
    }

    local total_files = vim.tbl_count(result.documentChanges)
    table.insert(
        msg,
        string.format(
            'Changed %s file%s. %s',
            total_files,
            total_files > 1 and 's' or '',
            -- the edits are not saved automatically, so remind us to save them
            total_files > 1 and 'To save them run `:wa`' or 'To save it run `:w`'
        )
    )

    -- list changed files (`documentChanges` can also hold file operations)
    for _, changes in pairs(result.documentChanges) do
        if changes.textDocument then
            table.insert(
                msg,
                ('- [%s] (%d changes)'):format(
                    vim.fs.relpath(
                        assert(vim.uv.cwd()),
                        vim.uri_to_fname(changes.textDocument.uri)
                    ),
                    #changes.edits
                )
            )
        end
    end

    Snacks.notify.info(msg, { title = 'LSP' })
end

--- Opens the rename popup and previews the rename in the current buffer.
---@param bufnr integer
---@param win integer window the request was made from
---@param client vim.lsp.Client
---@param position_params table `textDocument/rename` params, used for positioning
---@param curr_name string
local function open_rename_input(bufnr, win, client, position_params, curr_name)
    local encoding = client.offset_encoding

    -- preview state: byte spans of this buffer's occurrences
    ---@type table<integer, { s: integer, e: integer }[]>
    local refs = {}
    ---@type table<integer, string> line_nr -> original line text
    local orig = {}
    ---@type integer? changedtick right after our last preview mutation
    local preview_tick = nil
    local preview_active = false

    local function clear_preview()
        if not preview_active then
            return
        end
        preview_active = false
        if not vim.api.nvim_buf_is_valid(bufnr) or not vim.bo[bufnr].modifiable then
            return
        end
        -- the buffer was edited outside of the preview: restoring the cached
        -- lines would clobber those edits, so drop the preview instead
        if preview_tick ~= vim.api.nvim_buf_get_changedtick(bufnr) then
            refs, orig = {}, {}
            return
        end
        for line_nr, text in pairs(orig) do
            vim.api.nvim_buf_set_lines(bufnr, line_nr, line_nr + 1, false, { text })
        end
    end

    local function apply_preview(new_name)
        if not vim.bo[bufnr].modifiable then
            return
        end
        -- always preview from a clean slate
        clear_preview()
        if not next(refs) then
            return -- nothing to preview (or the buffer was edited behind our back)
        end
        for line_nr, spans in pairs(refs) do
            -- sort ascending so byte offsets accumulate correctly
            table.sort(spans, function(a, b)
                return a.s < b.s
            end)
            local offset = 0
            for _, span in ipairs(spans) do
                vim.api.nvim_buf_set_text(
                    bufnr,
                    line_nr,
                    span.s + offset,
                    line_nr,
                    span.e + offset,
                    { new_name }
                )
                offset = offset + #new_name - (span.e - span.s)
            end
        end
        preview_active = true
        preview_tick = vim.api.nvim_buf_get_changedtick(bufnr)
    end

    -- mutating other buffers would advance their LSP document version, causing
    -- apply_workspace_edit to consider them "newer than edits" and skip them,
    -- so only occurrences in the current buffer are previewed.
    local function fetch_references()
        client:request(
            'textDocument/references',
            vim.tbl_extend('force', position_params, {
                context = { includeDeclaration = true },
            }),
            function(err, result)
                if err or not result or vim.tbl_isempty(result) then
                    return
                end
                for _, ref in ipairs(result) do
                    local range = ref.range
                    -- skip multi-line ranges
                    if
                        range.start.line == range['end'].line
                        and vim.uri_to_bufnr(ref.uri) == bufnr
                    then
                        local line_nr = range.start.line
                        local text = vim.api.nvim_buf_get_lines(
                            bufnr,
                            line_nr,
                            line_nr + 1,
                            false
                        )[1]
                        if text then
                            orig[line_nr] = text
                            refs[line_nr] = refs[line_nr] or {}
                            table.insert(refs[line_nr], {
                                s = lsp_col_to_byte(
                                    text,
                                    range.start.character,
                                    encoding
                                ),
                                e = lsp_col_to_byte(
                                    text,
                                    range['end'].character,
                                    encoding
                                ),
                            })
                        end
                    end
                end
            end,
            bufnr
        )
    end

    local function on_submit(new_name)
        clear_preview()
        new_name = new_name and new_name:gsub('[\r\n]+', '') or ''
        if #new_name == 0 or new_name == curr_name then
            -- do nothing if `new_name` is empty or not changed
            return
        end

        -- fresh params: `client:request()` flushes pending didChange
        -- notifications first, so the server renames against the same text
        -- these positions were computed from
        local params = vim.lsp.util.make_position_params(win, encoding)
        ---@diagnostic disable-next-line: inject-field
        params.newName = new_name

        client:request('textDocument/rename', params, function(err, result)
            if err or not result then
                Snacks.notify.error({
                    'Error requesting rename',
                    err and err.message or 'not a renameable symbol',
                }, { title = 'LSP: ' .. client.name })
                return
            end

            -- the `result` contains all the places we need to update
            vim.lsp.util.apply_workspace_edit(result, encoding)
            notify_renamed(result, curr_name, new_name)
        end, bufnr)
    end

    local popup_options = {
        -- border for the window
        border = {
            style = 'rounded',
            text = {
                top = '[Rename]',
                top_align = 'left',
            },
        },
        -- highlight for the window
        highlight = 'Normal:Normal',
        -- place the popup window relative to the buffer position of the symbol
        relative = {
            type = 'buf',
            position = {
                row = position_params.position.line,
                col = position_params.position.character,
            },
        },
        -- position the popup window on the line below the symbol
        position = {
            row = 2,
            col = 1,
        },
        size = {
            width = math.max(#curr_name + 10, 25),
            height = 1,
        },
    }

    ---@diagnostic disable-next-line: call-non-callable, param-type-mismatch
    local input = Input(popup_options, {
        -- set the default value to the current name
        default_value = curr_name,
        on_submit = on_submit,
        prompt = '',
        ---@param value string
        on_change = function(value)
            vim.schedule(function()
                if value and #value > 0 then
                    apply_preview(value)
                else
                    clear_preview()
                end
            end)
        end,
    })

    input:mount()

    -- kick off reference fetching immediately so it's ready when user starts typing
    fetch_references()

    -- make it easier to move around long words
    -- NOTE: no longer needed to modify iskeyword due to nvim-spider
    -- vim.opt_local.iskeyword:remove { '_', '-' }

    -- go into normal mode
    vim.schedule(function()
        vim.api.nvim_command('stopinsert')
    end)

    -- submit on <CR> in normal mode
    input:map('n', '<CR>', function()
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes('i<CR>', true, false, true),
            'n',
            false
        )
        ---@diagnostic disable-next-line: param-type-mismatch
    end, { noremap = true })

    -- close on <esc> in normal mode
    input:map('n', '<esc>', function()
        clear_preview()
        input:unmount()
        ---@diagnostic disable-next-line: param-type-mismatch
    end, { noremap = true })

    -- close when cursor leaves the buffer
    input:on(event.BufLeave, function()
        clear_preview()
        input:unmount()
        ---@diagnostic disable-next-line: param-type-mismatch
    end, { once = true })
end

local function nui_lsp_rename()
    local bufnr = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    -- computed early: the cursor moves once the input popup is open
    local cword = vim.fn.expand('<cword>')

    local clients = vim.lsp.get_clients({
        bufnr = bufnr,
        -- clients must at least support rename, prepareRename is optional
        method = 'textDocument/rename',
    })
    if #clients == 0 then
        Snacks.notify.warn('No language server supports renaming', {
            title = 'LSP: rename',
        })
        return
    end

    -- try clients in order, like `vim.lsp.buf.rename()`
    local function try_client(idx)
        local client = clients[idx]
        if not client then
            Snacks.notify.info('Nothing to rename', { title = 'LSP: rename' })
            return
        end

        local encoding = client.offset_encoding
        local params = vim.lsp.util.make_position_params(win, encoding)

        local function open(default_name)
            open_rename_input(bufnr, win, client, params, default_name)
        end

        if not client:supports_method('textDocument/prepareRename', bufnr) then
            open(cword)
            return
        end

        -- let the server decide whether there is anything to rename, and what
        -- the current name is (it may differ from `<cword>`)
        client:request('textDocument/prepareRename', params, function(err, result)
            if err or result == nil then
                if clients[idx + 1] then
                    return try_client(idx + 1)
                end
                Snacks.notify.info(
                    err and ('Error on prepareRename: ' .. (err.message or ''))
                        or 'Nothing to rename',
                    { title = 'LSP: rename' }
                )
                return
            end

            -- `result` is either a range or `{ range = ..., placeholder = ... }`
            local range = result.range or (result.start and result)
            local curr_name = result.placeholder
                or (range and text_at_range(bufnr, range, encoding))
                or cword
            open(curr_name)
        end, bufnr)
    end

    try_client(1)
end

return {
    rename = nui_lsp_rename,
}
