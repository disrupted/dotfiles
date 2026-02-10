describe('gh wrapper', function()
    local calls
    local responses

    local function system_mock(cmd)
        table.insert(calls, cmd)
        local response = table.remove(responses, 1)
        if type(response) == 'function' then
            return response(cmd)
        end
        if response == '__error__' then
            error('mocked system failure')
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

    it('extracts PR url and keeps warning as stderr', function()
        responses = {
            {
                code = 0,
                stdout = {
                    'https://github.com/acme/repo/pull/171\n',
                    'Warning: 1 uncommitted change\n',
                },
            },
        }

        local gh = require 'gh'
        local stdout, stderr = gh.pr.create {
            title = 'test',
            body = 'body',
            label = {},
            draft = true,
        }

        assert.equals('https://github.com/acme/repo/pull/171', stdout)
        assert.equals('Warning: 1 uncommitted change', stderr)
    end)

    it('returns error when create exits non-zero', function()
        responses = {
            {
                code = 1,
                stdout = '',
                stderr = 'create failed',
            },
        }

        local gh = require 'gh'
        local stdout, stderr = gh.pr.create {
            title = 'test',
            body = 'body',
            label = {},
            draft = true,
        }

        assert.equals('', stdout)
        assert.equals('create failed', stderr)
    end)

    it('returns generic success when create output has no url', function()
        responses = {
            {
                code = 0,
                stdout = '',
                stderr = '',
            },
        }

        local gh = require 'gh'
        local stdout, stderr = gh.pr.create {
            title = 'test',
            body = 'body',
            label = {},
            draft = true,
        }

        assert.equals('PR created', stdout)
        assert.is_nil(stderr)
        assert.equals(1, #calls)
    end)

    it('converts system exceptions into stderr return', function()
        responses = { '__error__' }

        local gh = require 'gh'
        local stdout, stderr = gh.pr.create {
            title = 'test',
            body = 'body',
            label = {},
            draft = true,
        }

        assert.equals('', stdout)
        assert.matches('mocked system failure', stderr)
    end)
end)
