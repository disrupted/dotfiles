local ntf = require('ntf')
local describe, it = ntf.describe, ntf.it
local before_each, after_each = ntf.before_each, ntf.after_each
local assert = ntf.assert

-- `foobar` appears after a multibyte char, so utf-16 columns differ from bytes
local CONTENT = { 'local s = \'é\' .. foobar', 'print(foobar, foobar)' }
local RENAMED = { 'local s = \'é\' .. baz', 'print(baz, baz)' }

describe('LSP rename (nui input)', function()
    local captured
    local notes
    local prepare_result
    local rename_calls
    local client
    local bufnr
    local uri
    local occ

    local real_input
    local real_autocmd
    local real_get_clients
    local real_snacks

    --- LSP range of an occurrence, in the client's offset encoding
    --- @param o { line: integer, sb: integer, eb: integer }
    local function range(o)
        local line = CONTENT[o.line + 1]
        local enc = client.offset_encoding
        return {
            start = {
                line = o.line,
                character = vim.str_utfindex(line, enc, o.sb, false),
            },
            ['end'] = {
                line = o.line,
                character = vim.str_utfindex(line, enc, o.eb, false),
            },
        }
    end

    local function lines()
        return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    end

    local function rename_at(o)
        vim.api.nvim_win_set_cursor(0, { o.line + 1, o.sb })
        require('conf.lsp.nui').rename()
    end

    local function wait_for_preview(name)
        vim.wait(1000, function()
            return lines()[1]:find(name, 1, true) ~= nil
        end)
    end

    before_each(function()
        captured, notes, prepare_result, rename_calls = nil, {}, nil, {}

        occ = {}
        for i, line in ipairs(CONTENT) do
            local init = 1
            while true do
                local s, e = line:find('foobar', init, true)
                if not s then
                    break
                end
                occ[#occ + 1] = { line = i - 1, sb = s - 1, eb = e }
                init = e + 1
            end
        end

        bufnr = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(bufnr, vim.fn.tempname() .. '.lua')
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, CONTENT)
        vim.api.nvim_win_set_buf(0, bufnr)
        uri = vim.uri_from_bufnr(bufnr)

        client = {
            name = 'fake-ls',
            offset_encoding = 'utf-16',
            supports_method = function()
                return true
            end,
            request = function(_, method, params, cb)
                if method == 'textDocument/prepareRename' then
                    return cb(nil, prepare_result)
                elseif method == 'textDocument/references' then
                    local refs = {}
                    for _, o in ipairs(occ) do
                        refs[#refs + 1] = { uri = uri, range = range(o) }
                    end
                    return cb(nil, refs)
                elseif method == 'textDocument/rename' then
                    rename_calls[#rename_calls + 1] = params
                    local edits = {}
                    for _, o in ipairs(occ) do
                        edits[#edits + 1] = {
                            range = range(o),
                            newText = params.newName,
                        }
                    end
                    return cb(nil, {
                        documentChanges = {
                            {
                                textDocument = { uri = uri, version = vim.NIL },
                                edits = edits,
                            },
                        },
                    })
                end
            end,
        }

        -- never open a real floating input in tests
        real_input = package.loaded['nui.input']
        package.loaded['nui.input'] = function(popup_options, options)
            captured = { popup = popup_options, opts = options }
            return {
                mount = function() end,
                map = function() end,
                on = function() end,
                unmount = function() end,
            }
        end

        real_get_clients = vim.lsp.get_clients
        vim.lsp.get_clients = function()
            return { client }
        end

        real_autocmd = package.loaded['nui.utils.autocmd']
        package.loaded['nui.utils.autocmd'] = { event = { BufLeave = 'BufLeave' } }

        real_snacks = rawget(_G, 'Snacks')
        _G.Snacks = {
            notify = {
                info = function(msg)
                    notes[#notes + 1] = { 'info', msg }
                end,
                warn = function(msg)
                    notes[#notes + 1] = { 'warn', msg }
                end,
                error = function(msg)
                    notes[#notes + 1] = { 'error', msg }
                end,
            },
        }

        package.loaded['conf.lsp.nui'] = nil
        prepare_result = { range = range(occ[1]) }
    end)

    after_each(function()
        package.loaded['nui.input'] = real_input
        package.loaded['nui.utils.autocmd'] = real_autocmd
        package.loaded['conf.lsp.nui'] = nil
        vim.lsp.get_clients = real_get_clients
        _G.Snacks = real_snacks
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('defaults to the prepareRename range and anchors the popup', function()
        rename_at(occ[1])

        assert.no.is_nil(captured)
        assert.equal('foobar', captured.opts.default_value)
        assert.equal(occ[1].line, captured.popup.relative.position.row)
        assert.equal(
            vim.str_utfindex(CONTENT[occ[1].line + 1], 'utf-16', occ[1].sb, false),
            captured.popup.relative.position.col
        )
    end)

    it('previews every occurrence in the current buffer while typing', function()
        rename_at(occ[1])
        captured.opts.on_change('baz')
        wait_for_preview('baz')

        assert.same(RENAMED, lines())
    end)

    it('applies the rename on submit and lists the changed files', function()
        rename_at(occ[1])
        captured.opts.on_change('baz')
        wait_for_preview('baz')
        captured.opts.on_submit('baz')

        assert.same(RENAMED, lines())
        assert.equal(1, #rename_calls)
        assert.equal('baz', rename_calls[1].newName)
        assert.equal('info', notes[1][1])
    end)

    it('reverts the preview when the name is unchanged', function()
        rename_at(occ[1])
        captured.opts.on_change('qux')
        wait_for_preview('qux')
        captured.opts.on_submit('foobar')

        assert.same(CONTENT, lines())
        assert.equal(0, #rename_calls)
    end)

    it('prefers the prepareRename placeholder', function()
        prepare_result = {
            range = range(occ[1]),
            placeholder = 'PLACEHOLDER',
        }
        rename_at(occ[1])

        assert.equal('PLACEHOLDER', captured.opts.default_value)
    end)

    it('does not prompt when there is nothing to rename', function()
        prepare_result = nil
        rename_at(occ[1])

        assert.is_nil(captured)
        assert.equal('info', notes[1][1])
    end)

    it('reports a nil rename result without crashing', function()
        rename_at(occ[1])
        client.request = function(_, method, params, cb)
            if method == 'textDocument/prepareRename' then
                return cb(nil, prepare_result)
            elseif method == 'textDocument/references' then
                return cb(nil, {})
            end
            return cb(nil, nil)
        end
        captured.opts.on_submit('baz')

        assert.equal('error', notes[1][1])
    end)

    it('converts positions with the client offset encoding (utf-8)', function()
        client.offset_encoding = 'utf-8'
        prepare_result = { range = range(occ[1]) }
        rename_at(occ[1])
        captured.opts.on_change('baz')
        wait_for_preview('baz')

        assert.same(RENAMED, lines())
    end)
end)
