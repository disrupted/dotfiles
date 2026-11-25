local ntf = require('ntf')
local describe, it = ntf.describe, ntf.it
local assert = ntf.assert

local cwd = vim.uv.cwd() --[[@as string]]
local site = vim.fs.joinpath(vim.fn.stdpath('data') --[[@as string]], 'site')
vim.opt.rtp:prepend({
    cwd,
    site,
    vim.fs.joinpath(site, 'pack', 'core', 'opt', 'nvim-treesitter', 'runtime'),
})
vim.opt.rtp:append(vim.fs.joinpath(cwd, 'after'))
vim.cmd('filetype plugin on')
vim.treesitter.language.register('tsx', 'typescriptreact')
dofile(vim.fs.joinpath(cwd, 'plugin', 'comment.lua'))

---@param ft string
---@param lines string[]
---@param pos? [integer, integer]
local function setup_buf(ft, lines, pos)
    local buf = vim.api.nvim_create_buf(true, false)
    vim.bo[buf].bufhidden = 'wipe'
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = ft
    vim.treesitter.start(buf)
    vim.treesitter.get_parser(buf):parse(true)
    vim.api.nvim_win_set_cursor(0, pos or { 1, 0 })
    vim.o.undolevels = vim.o.undolevels
end

local function get_lines()
    return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function line(lnum)
    return vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
end

---@param keys string
local function feed(keys)
    vim.api.nvim_feedkeys(vim.keycode(keys), 'mx', false)
end

describe('comment', function()
    local tsx_element =
        { 'const A = () => (', '  <div>', '    <span>hi</span>', '  </div>', ')' }
    local tsx_map = {
        'const A = () => (',
        '  <ul>',
        '    {xs.map((x) => {',
        '      return x',
        '    })}',
        '  </ul>',
        ')',
    }
    local cases = {
        {
            'typescriptreact',
            'jsx element child',
            tsx_element,
            { 3, 4 },
            '    {/* <span>hi</span> */}',
        },
        {
            'typescriptreact',
            'jsx attribute',
            { 'const A = () => (', '  <div', '    className="x"', '  />', ')' },
            { 3, 4 },
            '    // className="x"',
        },
        {
            'typescriptreact',
            'function body inside jsx',
            tsx_map,
            { 4, 6 },
            '      // return x',
        },
        {
            'typescriptreact',
            'plain code',
            { 'const a = 1' },
            { 1, 0 },
            '// const a = 1',
        },
        {
            'markdown',
            'injected lua fence',
            { '# t', '', '```lua', 'local a = 1', '```' },
            { 4, 0 },
            '-- local a = 1',
        },
        {
            'html',
            'injected script',
            { '<script>', '  let a = 1', '</script>' },
            { 2, 2 },
            '  // let a = 1',
        },
        {
            'html',
            'injected style',
            { '<style>', '  a { color: red; }', '</style>' },
            { 2, 2 },
            '  /* a { color: red; } */',
        },
        {
            'svelte',
            'markup',
            { '<script>', '  let a = 1', '</script>', '<div>x</div>' },
            { 4, 0 },
            '<!-- <div>x</div> -->',
        },
        {
            'htmldjango',
            'template',
            { '<div>{{ x }}</div>' },
            { 1, 0 },
            '{# <div>{{ x }}</div> #}',
        },
        {
            'helm',
            'template',
            { 'a: {{ .Values.x }}' },
            { 1, 0 },
            '{{/* a: {{ .Values.x }} */}}',
        },
    }

    for _, case in ipairs(cases) do
        local ft, name, lines, pos, expected = unpack(case)
        it(
            ('gcc uses the commentstring at the cursor: %s %s'):format(ft, name),
            function()
                setup_buf(ft, lines, pos)
                feed('gcc')
                assert.equal(expected, line(pos[1]))
            end
        )
    end

    it('does not comment blank lines', function()
        setup_buf('lua', { 'local a = 1', '', '  ', 'local b = 2' })
        feed('gcG')
        assert.same({ '-- local a = 1', '', '  ', '-- local b = 2' }, get_lines())
        feed('gcG')
        assert.same({ 'local a = 1', '', '  ', 'local b = 2' }, get_lines())
    end)

    it('works in visual mode', function()
        setup_buf('lua', { 'local a = 1', '', 'local b = 2' })
        feed('Vjjgc')
        assert.same({ '-- local a = 1', '', '-- local b = 2' }, get_lines())
    end)

    it('undoes in one step', function()
        setup_buf('lua', { 'local a = 1', '', 'local b = 2' })
        feed('gcG')
        feed('u')
        assert.same({ 'local a = 1', '', 'local b = 2' }, get_lines())
    end)

    it('dot-repeats', function()
        setup_buf('lua', { 'local a = 1', '', 'local b = 2', 'local c = 3' })
        feed('gcj')
        feed('jj.')
        assert.same(
            { '-- local a = 1', '', '-- local b = 2', '-- local c = 3' },
            get_lines()
        )
    end)

    it('gcA appends a line comment', function()
        setup_buf('lua', { 'local a = 1  ' })
        feed('gcAnote<Esc>')
        assert.equal('local a = 1 -- note', line(1))
    end)

    it('gcA places the cursor inside a block comment', function()
        setup_buf('typescriptreact', tsx_element, { 3, 0 })
        feed('gcAnote<Esc>')
        assert.equal('    <span>hi</span> {/* note */}', line(3))
    end)

    it('gcA on a blank line comments at its indent', function()
        setup_buf('lua', { '  ' })
        feed('gcAnote<Esc>')
        assert.equal('  -- note', line(1))
    end)
end)
