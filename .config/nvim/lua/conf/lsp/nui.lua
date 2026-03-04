-- https://gist.github.com/MunifTanjim/8d9498c096719bdf4234321230fe3dc7
local Input = require 'nui.input'
local event = require('nui.utils.autocmd').event

local function nui_lsp_rename()
    local node = vim.treesitter.get_node()
    local curr_name = node and vim.treesitter.get_node_text(node, 0)
        or vim.fn.expand '<cword>'

    local params = vim.lsp.util.make_position_params(0, 'utf-16')

    -- preview state
    ---@type table<integer, table<integer, {start_col: integer, end_col: integer, orig_text: string}[]>>?
    local cached_refs = nil -- bufnr -> line_nr -> [{start_col, end_col, orig_text}]

    -- fetch and cache LSP references for preview; called once on mount
    local function fetch_references()
        local ref_params = vim.tbl_extend('force', params, {
            context = { includeDeclaration = true },
        })
        vim.lsp.buf_request(
            0,
            'textDocument/references',
            ref_params,
            function(err, result)
                if err or not result or vim.tbl_isempty(result) then
                    return
                end
                local refs = vim.defaulttable()
                for _, ref in ipairs(result) do
                    local range = ref.range
                    -- skip multi-line ranges
                    if range.start.line == range['end'].line then
                        local bufnr = vim.uri_to_bufnr(ref.uri)
                        if not vim.api.nvim_buf_is_loaded(bufnr) then
                            vim.fn.bufload(bufnr)
                        end
                        local line_nr = range.start.line
                        local start_col = range.start.character
                        local end_col = range['end'].character
                        local orig_text = vim.api.nvim_buf_get_lines(
                            bufnr,
                            line_nr,
                            line_nr + 1,
                            false
                        )[1]
                        table.insert(refs[bufnr][line_nr], {
                            start_col = start_col,
                            end_col = end_col,
                            orig_text = orig_text,
                        })
                    end
                end
                cached_refs = refs
            end
        )
    end

    -- clear all preview highlights and revert any in-buffer text mutations
    local function clear_preview()
        if not cached_refs then
            return
        end
        for bufnr, lines in pairs(cached_refs) do
            if vim.api.nvim_buf_is_valid(bufnr) then
                for line_nr, infos in pairs(lines) do
                    -- restore original line text
                    local orig = infos[1].orig_text
                    vim.api.nvim_buf_set_lines(
                        bufnr,
                        line_nr,
                        line_nr + 1,
                        false,
                        { orig }
                    )
                end
            end
        end
    end

    -- apply preview highlights for new_name across all cached reference sites
    local function apply_preview(new_name)
        if not cached_refs then
            return
        end
        -- first restore originals so we always apply from a clean slate
        clear_preview()
        for bufnr, lines in pairs(cached_refs) do
            if not vim.api.nvim_buf_is_valid(bufnr) then
                goto continue_bufnr
            end
            for line_nr, infos in pairs(lines) do
                -- sort ascending so offsets accumulate correctly
                table.sort(infos, function(a, b)
                    return a.start_col < b.start_col
                end)
                local offset = 0
                for _, info in ipairs(infos) do
                    local s = info.start_col + offset
                    local e = info.end_col + offset
                    vim.api.nvim_buf_set_text(
                        bufnr,
                        line_nr,
                        s,
                        line_nr,
                        e,
                        { new_name }
                    )
                    offset = offset
                        + #new_name
                        - (info.end_col - info.start_col)
                end
            end
            ::continue_bufnr::
        end
    end

    local function on_submit(new_name)
        clear_preview()
        if not new_name or #new_name == 0 or curr_name == new_name then
            -- do nothing if `new_name` is empty or not changed.
            return
        end

        -- add `newName` property to `params`.
        -- this is needed for making `textDocument/rename` request.
        params['newName'] = new_name

        -- send the `textDocument/rename` request to LSP server
        vim.lsp.buf_request(
            0,
            'textDocument/rename',
            params,
            function(err, result, ctx, _)
                local client = assert(vim.lsp.get_client_by_id(ctx.client_id))

                if err or not result then
                    Snacks.notify.error(
                        { 'Error requesting rename', err.message },
                        { title = 'LSP: ' .. client.name }
                    )
                    return
                end

                -- the `result` contains all the places we need to update the
                -- name of the identifier. so we apply those edits.
                vim.lsp.util.apply_workspace_edit(
                    result,
                    client and client.offset_encoding or 'utf-16'
                )

                -- display notification with the changed files
                if
                    result.documentChanges
                    and not vim.tbl_isempty(result.documentChanges)
                then
                    local msg = {
                        ('**Renamed `%s` -> `%s`**'):format(
                            curr_name,
                            new_name
                        ),
                    }

                    local total_files = vim.tbl_count(result.documentChanges)
                    table.insert(msg, '') -- empty line
                    table.insert(
                        msg,
                        string.format(
                            'Changed %s file%s. %s',
                            total_files,
                            total_files > 1 and 's' or '',
                            -- after the edits are applied, the files are not saved automatically.
                            -- let's remind ourselves to save those...
                            total_files > 1 and 'To save them run `:wa`'
                                or 'To save it run `:w`'
                        )
                    )

                    -- list changed files
                    for _, changes in pairs(result.documentChanges) do
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

                    Snacks.notify.info(msg, { title = 'LSP' })
                end
            end
        )
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
        -- highlight for the window.
        highlight = 'Normal:Normal',
        -- place the popup window relative to the
        -- buffer position of the identifier
        relative = {
            type = 'buf',
            position = {
                -- this is the same `params` we got earlier
                row = params.position.line,
                col = params.position.character,
            },
        },
        -- position the popup window on the line below identifier
        position = {
            row = 2,
            col = 1,
        },
        size = {
            width = math.max(#curr_name + 10, 25),
            height = 1,
        },
    }

    local input = Input(popup_options, {
        -- set the default value to current name
        default_value = curr_name,
        -- pass the `on_submit` callback function we wrote earlier
        on_submit = on_submit,
        prompt = '',
        ---@param input string
        on_change = function(input)
            vim.schedule(function()
                if input and #input > 0 then
                    apply_preview(input)
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
        vim.api.nvim_command 'stopinsert'
    end)

    -- close on <esc> in normal mode
    input:map('n', '<esc>', function()
        clear_preview()
        input.input_props.on_close()
    end, { noremap = true })

    -- close when cursor leaves the buffer
    input:on(event.BufLeave, function()
        clear_preview()
        input.input_props.on_close()
    end, { once = true })
end

return {
    rename = nui_lsp_rename,
}
