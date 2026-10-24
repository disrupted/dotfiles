local ntf = require('ntf')
local describe, it = ntf.describe, ntf.it
local assert = ntf.assert

describe('subvert (:S/:Subvert)', function()
    require('conf.subvert').setup()

    vim.o.ignorecase = true
    vim.o.smartcase = true

    local function set_lines(lines)
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
    end

    local function get_lines()
        return vim.api.nvim_buf_get_lines(0, 0, -1, false)
    end

    local function assert_lines(expected)
        assert.same(expected, get_lines())
    end

    it('substitutes all case variants', function()
        set_lines({ 'foo Foo FOO' })
        vim.cmd('%S/foo/bar/g')
        assert_lines({ 'bar Bar BAR' })
    end)

    it('expands braces on both sides', function()
        set_lines({ 'facility Facility FACILITY facilities Facilities FACILITIES' })
        vim.cmd('%S/facilit{y,ies}/building{,s}/g')
        assert_lines({ 'building Building BUILDING buildings Buildings BUILDINGS' })
    end)

    it('prefers the longest alternative', function()
        set_lines({ 'child children Child Children' })
        vim.cmd('%S/child{,ren}/adult{,s}/g')
        assert_lines({ 'adult adults Adult Adults' })
    end)

    it('reuses the left alternatives for empty braces on the right', function()
        set_lines({ 'foo foos Foo Foos FOO FOOS' })
        vim.cmd('%S/foo{,s}/bar{}/g')
        assert_lines({ 'bar bars Bar Bars BAR BARS' })
    end)

    it('defaults to the current line like :s', function()
        set_lines({ 'foo', 'foo', 'foo' })
        vim.cmd('S/foo/bar/')
        assert_lines({ 'bar', 'foo', 'foo' })
    end)

    it('accepts ! like abolish (current line)', function()
        set_lines({ 'foo', 'foo' })
        vim.cmd('S!/foo/bar/')
        assert_lines({ 'bar', 'foo' })
    end)

    it('supports % and explicit ranges', function()
        set_lines({ 'foo', 'foo', 'foo' })
        vim.cmd('%S/foo/bar/')
        assert_lines({ 'bar', 'bar', 'bar' })

        set_lines({ 'foo', 'foo', 'foo' })
        vim.cmd('2,3S/foo/bar/')
        assert_lines({ 'foo', 'bar', 'bar' })
    end)

    it('supports the I flag to disable case variants', function()
        set_lines({ 'foo Foo FOO' })
        vim.cmd('%S/foo/bar/Ig')
        assert_lines({ 'bar Foo FOO' })
    end)

    it('supports the w flag for whole words', function()
        set_lines({ 'mybox my_box myBox box boxes' })
        vim.cmd('%S/box{,es}/bag{,s}/wg')
        assert_lines({ 'mybox my_box myBox bag bags' })
    end)

    it('supports the v flag for variable words', function()
        set_lines({ 'mybox my_box myBox box' })
        vim.cmd('%S/box/bag/vg')
        assert_lines({ 'mybox my_bag myBag bag' })
    end)

    it('supports the n flag without modifying the buffer', function()
        set_lines({ 'foo foo' })
        vim.cmd('%S/foo/bar/ng')
        assert_lines({ 'foo foo' })
    end)

    it('deletes matches when the replacement is empty', function()
        set_lines({ 'foo Foo FOO' })
        vim.cmd('%S/foo//g')
        assert_lines({ '  ' })
    end)

    it('accepts a custom delimiter', function()
        set_lines({ 'foo Foo xfoo' })
        vim.cmd('%S,foo,bar,g')
        assert_lines({ 'bar Bar xbar' })
    end)

    it('accepts an escaped delimiter', function()
        set_lines({ 'foo/bar Foo/bar notfoo/bar' })
        vim.cmd('%S/foo\\/bar/baz/g')
        assert_lines({ 'baz Baz notbaz' })
    end)

    it('treats regex metacharacters literally', function()
        set_lines({ 'a*b axb ab', 'foo.bar fooXbar', 'a~b ab', 'a[0] a0' })
        vim.cmd('%S/a*b/z/g')
        vim.cmd('%S/foo.bar/baz/g')
        vim.cmd('%S/a~b/z/g')
        vim.cmd('%S/a[0]/z/g')
        assert_lines({ 'z axb ab', 'baz fooXbar', 'z ab', 'z a0' })
    end)

    it('is repeatable with &', function()
        set_lines({ 'foo Foo' })
        vim.cmd('S/foo/baz/')
        vim.cmd('normal! &')
        assert_lines({ 'baz Baz' })
    end)

    it('handles double underscores in case variants', function()
        set_lines({ 'b__g B_g B__G B__g' })
        vim.cmd('%S/b__g/x__y/g')
        assert_lines({ 'x__y X_y X__Y B__g' })
    end)

    it('provides the :Subvert alias', function()
        set_lines({ 'child children' })
        vim.cmd('%Subvert/child{,ren}/adult{,s}/g')
        assert_lines({ 'adult adults' })
    end)
end)
