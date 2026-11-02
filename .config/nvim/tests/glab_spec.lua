local ntf = require('ntf')
local describe, it = ntf.describe, ntf.it
local before_each, after_each = ntf.before_each, ntf.after_each
local assert = ntf.assert

describe('glab wrapper', function()
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
        package.loaded['glab'] = nil
    end)

    after_each(function()
        package.loaded['glab'] = nil
        vim.system = real_system
    end)

    ---@param fn async fun(): R...
    ---@return R...
    local function run(fn)
        return vim.async.run(fn):wait()
    end

    it('passes expected flags to mr create', function()
        responses = {
            {
                code = 0,
                stdout = 'https://git.example.org/group/repo/-/merge_requests/1\n',
                stderr = 'Creating merge request for branch in group/repo...\n',
            },
        }

        local glab = require('glab')
        local stdout, stderr, code = run(function()
            return glab.mr.create({
                title = 'test',
                body = 'body',
                assignee = 'me',
                draft = true,
                label = { 'bug', 'urgent' },
                target = 'main',
            })
        end)

        assert.same({
            'glab',
            'mr',
            'create',
            '--title',
            'test',
            '--description',
            'body',
            '--assignee',
            'me',
            '--draft',
            '--label',
            'bug',
            '--label',
            'urgent',
            '--target-branch',
            'main',
            '--remove-source-branch',
            '--squash-before-merge',
            '--yes',
        }, calls[1])
        assert.equal('https://git.example.org/group/repo/-/merge_requests/1', stdout)
        assert.equal('Creating merge request for branch in group/repo...', stderr)
        assert.equal(0, code)
    end)

    it('lists labels as JSON', function()
        responses = {
            {
                code = 0,
                stdout = '[{"name":"bug"},{"name":"urgent"}]',
            },
        }

        local glab = require('glab')
        local labels = run(function()
            return glab.labels()
        end)

        assert.same(
            { 'glab', 'label', 'list', '--output', 'json', '--per-page', '100' },
            calls[1]
        )
        assert.same({ { name = 'bug' }, { name = 'urgent' } }, labels)
    end)
end)
