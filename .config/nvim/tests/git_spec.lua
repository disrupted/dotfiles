local ntf = require('ntf')
local describe, it = ntf.describe, ntf.it
local before_each, after_each = ntf.before_each, ntf.after_each
local assert = ntf.assert

describe('git helpers', function()
    local git

    before_each(function()
        package.loaded['git'] = nil
        git = require('git')
    end)

    after_each(function()
        package.loaded['git'] = nil
        if git and git.close then
            git.close()
        end
    end)

    it('splits remote-tracking branch names', function()
        local remote, branch = git.split_remote_branch('origin/main')

        assert.equal('origin', remote)
        assert.equal('main', branch)
    end)

    it('preserves slashes in branch names', function()
        local remote, branch = git.split_remote_branch('upstream/feature/fix/foo')

        assert.equal('upstream', remote)
        assert.equal('feature/fix/foo', branch)
    end)

    it('returns nil remote for local branch names', function()
        local remote, branch = git.split_remote_branch('main')

        assert.is_nil(remote)
        assert.equal('main', branch)
    end)
end)
