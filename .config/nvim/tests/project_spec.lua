local ntf = require('ntf')
local describe, it = ntf.describe, ntf.it
local before_each, after_each = ntf.before_each, ntf.after_each
local assert = ntf.assert

describe('project (mise monorepo)', function()
    local project
    local root = '/repo'

    before_each(function()
        package.loaded['conf.project'] = nil
        project = require('conf.project')
        vim.g.workspace_root = root
    end)

    after_each(function()
        package.loaded['conf.project'] = nil
        vim.g.workspace_root = nil
        vim.g.project_roots = nil
    end)

    it('parses config roots into absolute paths', function()
        local roots = project._parse(root, {
            code = 0,
            signal = 0,
            stdout = '["backend", "frontend"]\n',
        })
        assert.same({ '/repo/backend', '/repo/frontend' }, roots)
    end)

    it('treats missing key, failures and garbage as no monorepo', function()
        assert.same({}, project._parse(root, { code = 1, signal = 0, stdout = '' }))
        assert.same({}, project._parse(root, { code = 0, signal = 0, stdout = '' }))
        assert.same({}, project._parse(root, { code = 0, signal = 0, stdout = 'nope' }))
    end)

    it('maps paths to the innermost config root', function()
        local candidates = { '/repo/backend', '/repo/frontend', '/repo/backend/packages/foo' }
        assert.equal('/repo/backend', project.of('/repo/backend/app/main.py', candidates))
        assert.equal(
            '/repo/backend/packages/foo',
            project.of('/repo/backend/packages/foo/src/x.py', candidates)
        )
        assert.equal('/repo/frontend', project.of('/repo/frontend', candidates))
        -- outside every config root: the workspace root
        assert.equal(root, project.of('/repo/.github/workflows/ci.yaml', candidates))
        -- prefix match must respect path segments
        assert.equal(root, project.of('/repo/backend-old/x.py', candidates))
    end)

    it('wraps commands in the mise env of non-workspace roots only', function()
        if vim.fn.executable('mise') == 0 then
            return
        end
        assert.same({ 'ty', 'server' }, project.exec(root, { 'ty', 'server' }))
        assert.same(
            { 'mise', '-C', '/repo/backend', 'exec', '--', 'ty', 'server' },
            project.exec('/repo/backend', { 'ty', 'server' })
        )
    end)
end)

describe('git worktree root', function()
    local git
    local tmp

    ---@param cmd string[]
    local function run(cmd)
        local out = vim.system(cmd, { text = true }):wait()
        assert.equal(0, out.code, table.concat(cmd, ' ') .. ': ' .. (out.stderr or ''))
    end

    before_each(function()
        package.loaded['git'] = nil
        git = require('git')
        tmp = vim.fs.normalize(assert(vim.uv.fs_realpath(vim.fn.tempname():match('^(.*)/') or '/tmp')))
        tmp = vim.fs.joinpath(tmp, 'wt-' .. vim.uv.hrtime())
        vim.fn.mkdir(tmp, 'p')
        local main = vim.fs.joinpath(tmp, 'main')
        run({ 'git', 'init', '-q', main })
        run({ 'git', '-C', main, '-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-q', '--allow-empty', '-m', 'init' })
        run({ 'git', '-C', main, 'worktree', 'add', '-q', vim.fs.joinpath(tmp, 'review') })
    end)

    after_each(function()
        package.loaded['git'] = nil
        vim.fn.delete(tmp, 'rf')
    end)

    it('returns the work tree root for the main checkout', function()
        local main = vim.fs.joinpath(tmp, 'main')
        local repo, toplevel = git.find_repo(vim.fs.joinpath(main))
        assert.equal(vim.fs.joinpath(main, '.git'), repo)
        assert.equal(main, toplevel)
    end)

    it('returns the linked worktree root, not the .git/worktrees dir', function()
        local review = vim.fs.joinpath(tmp, 'review')
        local repo, toplevel = git.find_repo(review)
        assert.equal(vim.fs.joinpath(tmp, 'main', '.git', 'worktrees', 'review'), repo)
        assert.equal(review, toplevel)
    end)

    it('returns no toplevel inside the Git dir', function()
        local repo, toplevel = git.find_repo(vim.fs.joinpath(tmp, 'main', '.git'))
        assert.equal(vim.fs.joinpath(tmp, 'main', '.git'), repo)
        assert.is_nil(toplevel)
    end)
end)
