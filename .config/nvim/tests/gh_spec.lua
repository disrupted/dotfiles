describe('gh wrapper', function()
    local calls
    local responses

    local function system_mock(cmd)
        table.insert(calls, cmd)
        local response = table.remove(responses, 1)
        if type(response) == 'function' then
            return response(cmd)
        end
        return response
    end

    before_each(function()
        calls = {}
        responses = {}
        package.loaded['gh'] = nil
        package.loaded['coop.vim'] = {
            system = system_mock,
        }
    end)

    after_each(function()
        package.loaded['gh'] = nil
        package.loaded['coop.vim'] = nil
    end)

    it('returns trimmed stdout from run', function()
        responses = {
            {
                code = 0,
                stdout = '  hello world\n',
            },
        }

        local gh = require 'gh'
        local out = gh.run { 'repo', 'view' }

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
        gh.pr.create {
            title = 'test',
            body = 'body',
            assignee = 'me',
            draft = true,
            label = { 'bug', 'urgent' },
            base = 'main',
        }

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
        local stdout, stderr = gh.pr.create {
            title = 'test',
            body = 'body',
            label = {},
        }

        assert.equals('stdout text\n', stdout)
        assert.equals('stderr text\n', stderr)
    end)
end)
