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
    local prev = vim.api.nvim_get_current_buf()
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_delete(prev, { force = true })
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
    -- { filetype, name, lines, first line, last line, expected commented range }
    local cases = {
        {
            'typescriptreact',
            'jsx element child',
            tsx_element,
            3,
            3,
            { '    {/* <span>hi</span> */}' },
        },
        {
            'typescriptreact',
            'jsx expression child',
            { 'const A = () => (', '  <div>', '    {render()}', '  </div>', ')' },
            3,
            3,
            { '    {/* {render()} */}' },
        },
        {
            'typescriptreact',
            'jsx attribute',
            { 'const A = () => (', '  <div', '    className="x"', '  />', ')' },
            3,
            3,
            { '    // className="x"' },
        },
        {
            'typescriptreact',
            'function body inside jsx',
            tsx_map,
            4,
            4,
            { '      // return x' },
        },
        {
            'typescriptreact',
            'call argument inside jsx',
            {
                'const A = () => (',
                '  <ul>',
                '    {fmt(',
                '      value,',
                '    )}',
                '  </ul>',
                ')',
            },
            4,
            4,
            { '      // value,' },
        },
        {
            'typescriptreact',
            'plain code',
            { 'const a = f(1)' },
            1,
            1,
            { '// const a = f(1)' },
        },
        {
            'markdown',
            'inside a lua fence',
            { '```lua', 'local a = 1', '```' },
            2,
            2,
            { '-- local a = 1' },
        },
        {
            'markdown',
            'whole lua fence',
            { '```lua', 'local a = 1', '```' },
            1,
            3,
            { '<!-- ```lua -->', '<!-- local a = 1 -->', '<!-- ``` -->' },
        },
        {
            'lua',
            'inside vim.cmd',
            { 'vim.cmd([[', '  set nu', ']])' },
            2,
            2,
            { '  "set nu' },
        },
        {
            'lua',
            'whole vim.cmd',
            { 'vim.cmd([[', '  set nu', ']])' },
            1,
            3,
            { '-- vim.cmd([[', '--   set nu', '-- ]])' },
        },
        {
            'html',
            'injected script',
            { '<script>', '  let a = 1', '</script>' },
            2,
            2,
            { '  // let a = 1' },
        },
        {
            'html',
            'injected style',
            { '<style>', '  a { color: red; }', '</style>' },
            2,
            2,
            { '  /* a { color: red; } */' },
        },
        {
            'svelte',
            'markup',
            { '<script>', '  let a = 1', '</script>', '<div>x</div>' },
            4,
            4,
            { '<!-- <div>x</div> -->' },
        },
        { 'htmldjango', 'html', { '<div>x</div>' }, 1, 1, { '<!-- <div>x</div> -->' } },
        {
            'htmldjango',
            'html with tag',
            { '<div>{{ x }}</div>' },
            1,
            1,
            { '{# <div>{{ x }}</div> #}' },
        },
        { 'htmldjango', 'tag', { '{% if x %}' }, 1, 1, { '{# {% if x %} #}' } },
        { 'helm', 'yaml', { 'a:', '  b: c' }, 1, 2, { '# a:', '#   b: c' } },
        {
            'helm',
            'yaml with action',
            { 'a: {{ .Values.x }}' },
            1,
            1,
            { '{{/* a: {{ .Values.x }} */}}' },
        },
        {
            'helm',
            'action block',
            { '{{- if .X }}', 'a: b', '{{- end }}' },
            1,
            3,
            { '{{/* {{- if .X }} */}}', '{{/* a: b */}}', '{{/* {{- end }} */}}' },
        },
    }

    for _, case in ipairs(cases) do
        local ft, name, lines, first, last, expected = unpack(case)
        it(('gc ignores the cursor column: %s %s'):format(ft, name), function()
            local keys = first == last and 'gcc' or ('gc%dj'):format(last - first)
            for col = 0, #lines[first] - 1 do
                setup_buf(ft, lines, { first, col })
                feed(keys)
                assert.same(
                    expected,
                    vim.api.nvim_buf_get_lines(0, first - 1, last, false)
                )
                vim.api.nvim_win_set_cursor(0, { first, 0 })
                feed(keys)
                assert.same(lines, get_lines())
            end
        end)
    end

    it('gc{motion} from inside an injection uses the host language', function()
        setup_buf(
            'lua',
            { 'vim.cmd(\'echo 1\')', 'return vim.cmd(\'echo 1\')' },
            { 1, 9 }
        )
        feed('gcG')
        assert.same(
            { '-- vim.cmd(\'echo 1\')', '-- return vim.cmd(\'echo 1\')' },
            get_lines()
        )
    end)

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
