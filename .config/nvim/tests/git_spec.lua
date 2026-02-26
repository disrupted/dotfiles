describe('git helpers', function()
    local git

    before_each(function()
        package.loaded['git'] = nil
        git = require 'git'
    end)

    after_each(function()
        package.loaded['git'] = nil
        if git and git.close then
            git.close()
        end
    end)

    it('splits remote-tracking branch names', function()
        local remote, branch = git.split_remote_branch 'origin/main'

        assert.equals('origin', remote)
        assert.equals('main', branch)
    end)

    it('preserves slashes in branch names', function()
        local remote, branch =
            git.split_remote_branch 'upstream/feature/fix/foo'

        assert.equals('upstream', remote)
        assert.equals('feature/fix/foo', branch)
    end)

    it('returns nil remote for local branch names', function()
        local remote, branch = git.split_remote_branch 'main'

        assert.is_nil(remote)
        assert.equals('main', branch)
    end)
end)
