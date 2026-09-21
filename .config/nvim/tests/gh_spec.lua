describe('gh wrapper', function()
    local calls
    local responses
    local real_system

    local function system_mock(cmd, _, cb)
        table.insert(calls, cmd)
        local response = table.remove(responses, 1)
        if type(response) == 'function' then
            response = response(cmd)
        end
        vim.schedule(function()
            cb(response)
        end)
    end

    before_each(function()
        calls = {}
        responses = {}
        real_system = vim.system
        vim.system = system_mock
        package.loaded['gh'] = nil
    end)

    after_each(function()
        package.loaded['gh'] = nil
        vim.system = real_system
    end)

    ---@param fn async fun(): R...
    ---@return R...
    local function run(fn)
        return vim.async.run(fn):wait()
    end

    it('returns trimmed stdout from run', function()
        responses = {
            {
                code = 0,
                stdout = '  hello world\n',
            },
        }

        local gh = require 'gh'
        local out = run(function()
            return gh.run { 'repo', 'view' }
        end)

        assert.equals('hello world', out)
        assert.same({ 'gh', 'repo', 'view' }, calls[1])
    end)

    it('passes expected flags to pr create', function()
        responses = {
            {
                code = 0,
                stdout = 'ok',
                stderr = '',
            },
        }

        local gh = require 'gh'
        run(function()
            gh.pr.create {
                title = 'test',
                body = 'body',
                assignee = 'me',
                draft = true,
                label = { 'bug', 'urgent' },
                base = 'main',
            }
        end)

        assert.same({
            'gh',
            'pr',
            'create',
            '--title',
            'test',
            '--body',
            'body',
            '--assignee',
            'me',
            '--draft',
            '--label',
            'bug',
            '--label',
            'urgent',
            '--base',
            'main',
        }, calls[1])
    end)

    it('returns raw stdout and stderr from pr create', function()
        responses = {
            {
                code = 1,
                stdout = 'stdout text\n',
                stderr = 'stderr text\n',
            },
        }

        local gh = require 'gh'
        local stdout, stderr = run(function()
            return gh.pr.create {
                title = 'test',
                body = 'body',
                label = {},
            }
        end)

        assert.equals('stdout text\n', stdout)
        assert.equals('stderr text\n', stderr)
    end)
end)