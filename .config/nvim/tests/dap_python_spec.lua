local ntf = require('ntf')
local describe, it = ntf.describe, ntf.it
local before_each, after_each = ntf.before_each, ntf.after_each
local assert = ntf.assert

describe('dap python (mise monorepo)', function()
    local py
    local root = '/repo'
    local backend = '/repo/backend'

    before_each(function()
        package.loaded['conf.project'] = nil
        package.loaded['conf.dap.python'] = nil
        local project = require('conf.project')
        project.roots = function()
            return { backend }
        end
        project.executable = function(r, bin, cb)
            cb(r .. '/.venv/bin/' .. bin)
        end
        py = require('conf.dap.python')
        vim.g.workspace_root = root
    end)

    after_each(function()
        package.loaded['conf.project'] = nil
        package.loaded['conf.dap.python'] = nil
        vim.g.workspace_root = nil
    end)

    it('extracts the config root from a project.exec command', function()
        assert.equal(backend, py.exec_root({ 'mise', '-C', backend, 'exec', '--', 'python' }))
        assert.is_nil(py.exec_root({ 'python' }))
        assert.is_nil(py.exec_root('/usr/bin/python3'))
    end)

    it('runs launch configs in the config root of program', function()
        local result
        py.resolve({ request = 'launch', program = backend .. '/app/main.py' }, function(c)
            result = c
        end)
        assert.same({ 'mise', '-C', backend, 'exec', '--', 'python' }, result.python)
        assert.equal(backend, result.cwd)
        assert.equal(backend .. '/.venv/bin/python', result.debugLauncherPython)
    end)

    it('adds a launcher python to project.exec commands (neotest)', function()
        local result
        py.resolve({
            request = 'launch',
            program = '/tmp/neotest.py',
            python = { 'mise', '-C', backend, 'exec', '--', 'python' },
            cwd = root,
        }, function(c)
            result = c
        end)
        assert.equal(backend, result.cwd)
        assert.equal(backend .. '/.venv/bin/python', result.debugLauncherPython)
    end)

    it('leaves configs outside config roots and explicit settings alone', function()
        local result
        py.resolve({ request = 'launch', program = '/repo/scripts/x.py' }, function(c)
            result = c
        end)
        assert.is_nil(result.python)
        assert.is_nil(result.cwd)

        py.resolve({
            request = 'launch',
            program = backend .. '/app/main.py',
            pythonPath = '/opt/python',
            cwd = '/elsewhere',
        }, function(c)
            result = c
        end)
        assert.is_nil(result.python)
        assert.equal('/elsewhere', result.cwd)
        assert.is_nil(result.debugLauncherPython)

        py.resolve({ request = 'attach', program = backend .. '/x.py' }, function(c)
            result = c
        end)
        assert.is_nil(result.python)
    end)
end)
