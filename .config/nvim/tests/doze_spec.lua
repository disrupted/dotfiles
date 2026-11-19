local ntf = require('ntf')
local describe, it = ntf.describe, ntf.it
local before_each, after_each = ntf.before_each, ntf.after_each
local assert = ntf.assert

local config_dir = vim.uv.cwd()

---@param root string
---@param name string
---@param files table<string, string>
---@return string
local function make_repo(root, name, files)
    local dir = vim.fs.joinpath(root, 'repos', name)
    for rel, content in pairs(files) do
        local file = vim.fs.joinpath(dir, rel)
        vim.fn.mkdir(vim.fs.dirname(file), 'p')
        vim.fn.writefile(vim.split(content, '\n'), file)
    end
    local function git(...)
        vim.system(
            { 'git', '-c', 'user.name=doze', '-c', 'user.email=doze@local', ... },
            { cwd = dir }
        ):wait()
    end
    git('init', '-q')
    git('add', '-A')
    git('commit', '-qm', 'init')
    return dir
end

--- Runs a fresh nvim with isolated XDG dirs: `init` runs before startup finishes, `after` once it settled.
--- Both write into the global `R`, which comes back decoded.
---@param root string
---@param init string
---@param after string
---@param args? string[]
---@return table
local function session(root, init, after, args)
    local out = vim.fs.joinpath(root, 'result.json')
    vim.fn.delete(out)
    local init_file = vim.fs.joinpath(root, 'init.lua')
    vim.fn.writefile(
        vim.split(
            table.concat({
                ('package.path = %q .. package.path'):format(
                    config_dir .. '/lua/?.lua;' .. config_dir .. '/lua/?/init.lua;'
                ),
                'R = { order = {} }',
                'vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = function()',
                '  vim.defer_fn(function()',
                after,
                ('    vim.fn.writefile({ vim.json.encode(R) }, %q)'):format(out),
                '    vim.cmd("qa!")',
                '  end, 100)',
                'end })',
                init,
            }, '\n'),
            '\n'
        ),
        init_file
    )
    local cmd = { vim.v.progpath, '--headless', '-u', init_file }
    vim.list_extend(cmd, args or {})
    local result = vim.system(cmd, {
        env = {
            XDG_CONFIG_HOME = vim.fs.joinpath(root, 'config'),
            XDG_DATA_HOME = vim.fs.joinpath(root, 'data'),
            XDG_STATE_HOME = vim.fs.joinpath(root, 'state'),
            XDG_CACHE_HOME = vim.fs.joinpath(root, 'cache'),
        },
        timeout = 30000,
    }):wait()
    local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(out), '\n'))
    assert.is_true(
        ok,
        ('session failed (exit %d): %s'):format(result.code, result.stderr)
    )
    return decoded
end

local function counter(name)
    return ('vim.g.%s = (vim.g.%s or 0) + 1'):format(name, name)
end

describe('doze', function()
    local root

    before_each(function()
        root = vim.fn.tempname()
        vim.fn.mkdir(root, 'p')
    end)

    after_each(function()
        vim.fn.delete(root, 'rf')
    end)

    it('loads plugins at startup and on triggers', function()
        local r = {}
        r.first = make_repo(root, 'first', { ['lua/first.lua'] = 'return {}' })
        r.eager = make_repo(root, 'eager', {
            ['plugin/eager.lua'] = counter('eager_plugin'),
            ['after/plugin/eager.lua'] = counter('eager_after'),
        })
        r.lib = make_repo(root, 'lib.nvim', {
            ['lua/lib/init.lua'] = 'return { name = "lib" }',
            ['plugin/lib.lua'] = counter('lib_plugin'),
        })
        r.idle =
            make_repo(root, 'idle', { ['plugin/idle.lua'] = counter('idle_plugin') })
        r.subby =
            make_repo(root, 'subby', { ['lua/subby/x.lua'] = 'return { x = true }' })
        r.dep = make_repo(root, 'dep', {
            ['after/plugin/dep.lua'] = 'vim.g.dep_saw_parent = pcall(require, "parent")',
        })
        r.parent = make_repo(root, 'parent', {
            ['lua/parent/init.lua'] = 'return {}',
            ['plugin/parent.lua'] = [[
vim.api.nvim_create_user_command('ParentCmd', function(o) vim.g.parent_args = o.args end, {
  nargs = '*',
  complete = function() return { 'alpha', 'beta' } end,
})]],
        })
        r.cmdp = make_repo(root, 'cmdp', {
            ['plugin/cmdp.lua'] = [[
vim.api.nvim_create_user_command('CmdP', function(o) vim.g.cmdp = o.args .. (o.bang and '!' or '') end, { nargs = '*', bang = true })]],
        })
        r.evt = make_repo(root, 'evt', {
            ['plugin/evt.lua'] = [[
vim.api.nvim_create_autocmd('InsertEnter', {
  group = vim.api.nvim_create_augroup('evt', {}),
  callback = function() vim.g.evt_saw = (vim.g.evt_saw or 0) + 1 end,
})]],
        })
        r.ftp = make_repo(root, 'ftp', {
            ['plugin/ftp.lua'] = [[
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('ftp', {}),
  pattern = 'markdown',
  callback = function(ev) vim.g.ft_buf = ev.buf end,
})]],
        })
        r.keyp = make_repo(root, 'keyp', {
            ['plugin/keyp.lua'] = [[vim.keymap.set('n', '<F5>', function() vim.g.f5 = (vim.g.f5 or 0) + 1 end)]],
        })
        r.off = make_repo(root, 'off', { ['lua/off/init.lua'] = 'return {}' })
        r.vl = make_repo(root, 'vl', { ['lua/vl.lua'] = 'return {}' })

        local function cfg(name)
            return ('config = function() table.insert(R.order, %q) end'):format(name)
        end
        local init = table.concat({
            'require("doze").setup({',
            ('{ src = %q, lazy = false, priority = 10, %s },'):format(
                r.eager,
                cfg('eager')
            ),
            ('{ src = %q, lazy = false, priority = 100, %s },'):format(
                r.first,
                cfg('first')
            ),
            ('{ src = %q, %s },'):format(r.lib, cfg('lib')),
            ('{ src = %q },'):format(r.idle),
            ('{ src = %q, %s },'):format(r.subby, cfg('subby')),
            ('{ src = %q, %s },'):format(r.dep, cfg('dep')),
            ('{ src = %q, dependencies = { "dep" }, cmd = "ParentCmd", %s },'):format(
                r.parent,
                cfg('parent')
            ),
            ('{ src = %q, cmd = "CmdP" },'):format(r.cmdp),
            ('{ src = %q, event = "InsertEnter" },'):format(r.evt),
            ('{ src = %q, ft = "markdown" },'):format(r.ftp),
            ('{ src = %q, keys = { { "<F5>" }, { "<F6>", function() vim.g.f6 = (vim.g.f6 or 0) + 1 end } } },'):format(
                r.keyp
            ),
            ('{ src = %q, enabled = false },'):format(r.off),
            ('{ src = %q, event = "VeryLazy", %s },'):format(r.vl, cfg('vl')),
            '})',
            'R.lib_at_init = require("lib").name',
            'R.lib_configured = vim.tbl_contains(R.order, "lib")',
        }, '\n')
        local after = [[
    R.counts = { eager_plugin = vim.g.eager_plugin, eager_after = vim.g.eager_after, lib_plugin = vim.g.lib_plugin, idle = vim.g.idle_plugin }
    R.subby = require('subby.x').x
    R.completion = vim.fn.getcompletion('ParentCmd ', 'cmdline')
    vim.cmd('ParentCmd one two')
    R.parent_args = vim.g.parent_args
    R.dep_saw_parent = vim.g.dep_saw_parent
    vim.cmd('CmdP a b')
    vim.cmd('CmdP! c')
    R.cmdp = vim.g.cmdp
    vim.api.nvim_exec_autocmds('InsertEnter', {})
    vim.api.nvim_exec_autocmds('InsertEnter', {})
    R.evt_saw = vim.g.evt_saw
    vim.cmd('enew')
    vim.bo.filetype = 'markdown'
    R.ft_buf_ok = vim.g.ft_buf == vim.api.nvim_get_current_buf()
    vim.api.nvim_feedkeys(vim.keycode('<F5><F5><F6><F6>'), 'mx', false)
    R.f5, R.f6 = vim.g.f5, vim.g.f6
    R.off_loaded = pcall(require, 'off')
    R.off_installed = vim.uv.fs_stat(vim.fn.stdpath('data') .. '/site/pack/core/opt/off') ~= nil
    R.idle_on_rtp = vim.tbl_contains(vim.opt.rtp:get(), vim.fn.stdpath('data') .. '/site/pack/core/opt/idle')
]]

        for _, run in ipairs({ 'install', 'warm' }) do
            local res = session(root, init, after)
            assert.same(
                { 'first', 'eager', 'lib', 'vl', 'subby', 'dep', 'parent' },
                res.order,
                run
            )
            assert.equal('lib', res.lib_at_init, run)
            assert.is_true(res.lib_configured, run)
            assert.same(
                { eager_plugin = 1, eager_after = 1, lib_plugin = 1 },
                res.counts,
                run
            )
            assert.is_true(res.subby, run)
            assert.same({ 'alpha', 'beta' }, res.completion, run)
            assert.equal('one two', res.parent_args, run)
            assert.is_true(res.dep_saw_parent, run)
            assert.equal('c!', res.cmdp, run)
            assert.equal(2, res.evt_saw, run)
            assert.is_true(res.ft_buf_ok, run)
            assert.equal(2, res.f5, run)
            assert.equal(2, res.f6, run)
            assert.is_false(res.off_loaded, run)
            assert.is_true(res.off_installed, run)
            assert.is_false(res.idle_on_rtp, run)
        end
    end)

    it('sources a plugin triggered during startup once', function()
        local md = make_repo(root, 'md', {
            ['plugin/md.lua'] = counter('md_plugin'),
            ['after/plugin/md.lua'] = counter('md_after'),
            ['ftplugin/markdown.lua'] = counter('md_ftplugin'),
        })
        local file = vim.fs.joinpath(root, 'notes.md')
        vim.fn.writefile({ '# notes' }, file)
        for _, run in ipairs({ 'install', 'warm' }) do
            local res = session(
                root,
                ('require("doze").setup({ { src = %q, ft = "markdown" } })'):format(md),
                'R.counts = { vim.g.md_plugin, vim.g.md_after, vim.g.md_ftplugin }',
                { file }
            )
            assert.same({ 1, 1, 1 }, res.counts, run)
        end
    end)

    it('sources a plugin required from a plugin/ file once', function()
        local trig =
            make_repo(root, 'trig', { ['plugin/trig.lua'] = 'require("late")' })
        local late = make_repo(root, 'late', {
            ['lua/late.lua'] = 'return {}',
            ['plugin/late.lua'] = counter('late_plugin'),
            ['after/plugin/late.lua'] = counter('late_after'),
        })
        for _, run in ipairs({ 'install', 'warm' }) do
            local res = session(
                root,
                ('require("doze").setup({ { src = %q, lazy = false }, { src = %q } })'):format(
                    trig,
                    late
                ),
                'R.counts = { vim.g.late_plugin, vim.g.late_after }'
            )
            assert.same({ 1, 1 }, res.counts, run)
        end
    end)

    it('loads the plugin that has the required file', function()
        local ext = make_repo(
            root,
            'ext',
            { ['lua/shared/ext.lua'] = 'return { from = "ext" }' }
        )
        local owner = make_repo(
            root,
            'owner',
            { ['lua/shared/init.lua'] = 'return { from = "owner" }' }
        )
        local res = session(
            root,
            ('require("doze").setup({ { src = %q, %s }, { src = %q, %s } })'):format(
                ext,
                'config = function() table.insert(R.order, "ext") end',
                owner,
                'config = function() table.insert(R.order, "owner") end'
            ),
            [[
    R.root = require('shared').from
    R.before_ext = vim.deepcopy(R.order)
    R.ext = require('shared.ext').from
]]
        )
        assert.equal('owner', res.root)
        assert.same({ 'owner' }, res.before_ext)
        assert.equal('ext', res.ext)
        assert.same({ 'owner', 'ext' }, res.order)
    end)

    it('finishes install builds before loading', function()
        local slow = make_repo(root, 'slow', { ['lua/slow.lua'] = 'return {}' })
        local colon = make_repo(
            root,
            'colon',
            { ['plugin/colon.lua'] = 'vim.g.colon_ready = true' }
        )
        local fnb = make_repo(root, 'fnb', { ['lua/fnb.lua'] = 'return {}' })
        local res = session(
            root,
            table.concat({
                'require("doze").setup({',
                ('{ src = %q, lazy = false, build = "sleep 1 && touch built", config = function(p) R.built_at_config = vim.uv.fs_stat(p.path .. "/built") ~= nil end },'):format(
                    slow
                ),
                ('{ src = %q, build = ":let g:colon_built = g:colon_ready" },'):format(
                    colon
                ),
                ('{ src = %q, build = function(p) vim.g.fn_built = p.name end },'):format(
                    fnb
                ),
                '})',
            }, '\n'),
            [[
    R.colon_built = vim.g.colon_built
    R.fn_built = vim.g.fn_built
]]
        )
        assert.is_true(res.built_at_config)
        assert.is_true(res.colon_built)
        assert.equal('fnb', res.fn_built)
    end)

    it('rejects undeclared dependencies and unknown fields', function()
        package.loaded['doze.loader'] = nil
        local ok, err = pcall(require('doze.loader').register, {
            { src = 'https://example.com/a', dependencies = { 'missing' } },
            { src = 'https://example.com/b', opts = {} },
        })
        package.loaded['doze.loader'] = nil
        assert.is_false(ok)
        assert.match('a depends on undeclared missing', err)
        assert.match('b has unknown field `opts`', err)
    end)

    it('runs shell builds without blocking', function()
        package.loaded['doze.build'] = nil
        local done = vim.fs.joinpath(root, 'done')
        local start = vim.uv.hrtime()
        require('doze.build').run({
            name = 'async',
            path = root,
            spec = { src = 'x', build = 'sleep 0.3 && touch done' },
        })
        local elapsed_ms = (vim.uv.hrtime() - start) / 1e6
        package.loaded['doze.build'] = nil
        assert.is_true(elapsed_ms < 200)
        assert.is_true(vim.wait(5000, function()
            return vim.uv.fs_stat(done) ~= nil
        end))
    end)
end)
