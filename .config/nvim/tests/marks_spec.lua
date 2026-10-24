local ntf = require('ntf')
local describe, it = ntf.describe, ntf.it
local before_each, after_each = ntf.before_each, ntf.after_each
local assert = ntf.assert

describe('native file marks', function()
    local marks
    local picker_opts
    local mappings
    local real_snacks
    local real_keymap_set

    before_each(function()
        real_snacks = package.loaded['snacks']
        real_keymap_set = vim.keymap.set
        package.loaded['snacks'] = {
            picker = {
                marks = function(opts)
                    picker_opts = opts
                end,
            },
        }
        vim.keymap.set = function(mode, lhs, rhs, opts)
            table.insert(mappings, { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
        end
        mappings = {}
        picker_opts = nil
        package.loaded['conf.marks'] = nil
        marks = require('conf.marks')
    end)

    after_each(function()
        package.loaded['snacks'] = real_snacks
        vim.keymap.set = real_keymap_set
        package.loaded['conf.marks'] = nil
    end)

    it('keeps file marks A-Z only', function()
        assert.no.is_nil(marks.transform({ label = 'A' }))
        assert.no.is_nil(marks.transform({ label = 'Z' }))
        assert.is_false(marks.transform({ label = '0' }))
        assert.is_false(marks.transform({ label = '"' }))
        assert.is_false(marks.transform({ label = '^' }))
        assert.is_false(marks.transform({ label = nil }))
    end)

    it('opens a global-only picker', function()
        marks.picker()

        assert.equal('Marks', picker_opts.title)
        assert.is_true(picker_opts.global)
        assert.is_false(picker_opts['local'])
        assert.is_false(picker_opts.transform({ label = '0' }))
        assert.no.is_nil(picker_opts.transform({ label = 'A' }))
    end)

    it('maps the picker to <leader>m only', function()
        marks.setup()

        assert.equal(1, #mappings)
        assert.equal('n', mappings[1].mode)
        assert.equal('<leader>m', mappings[1].lhs)
        assert.equal('Marks', mappings[1].opts.desc)
    end)
end)
