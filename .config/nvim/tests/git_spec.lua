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

describe('git remote type detection', function()
    local git
    local gitlab_host

    before_each(function()
        package.loaded['git'] = nil
        git = require('git')
        gitlab_host = vim.env.GITLAB_HOST
    end)

    after_each(function()
        vim.env.GITLAB_HOST = gitlab_host
        if git and git.close then
            git.close()
        end
    end)

    it('extracts hosts from common remote URL formats', function()
        assert.equal('github.com', git.remote_host('git@github.com:owner/repo.git'))
        assert.equal('github.com', git.remote_host('https://github.com/owner/repo.git'))
        assert.equal(
            'git.example.org',
            git.remote_host('ssh://git@git.example.org:2222/group/repo.git')
        )
        assert.is_nil(git.remote_host(nil))
        assert.is_nil(git.remote_host(''))
    end)

    it('detects GitHub remotes', function()
        assert.equal('github', git.match_remote_type('git@github.com:owner/repo.git'))
        assert.equal(
            'github',
            git.match_remote_type('https://github.com/owner/repo.git')
        )
    end)

    it('detects self-hosted GitLab via GITLAB_HOST', function()
        vim.env.GITLAB_HOST = 'https://git.example.org/'

        assert.equal(
            'gitlab',
            git.match_remote_type('git@git.example.org:group/repo.git')
        )
        assert.equal(
            'gitlab',
            git.match_remote_type('https://git.example.org/group/repo.git')
        )
        assert.equal(
            'gitlab',
            git.match_remote_type('ssh://git@git.example.org:2222/group/repo.git')
        )
    end)

    it('returns nil for unsupported or missing remotes', function()
        vim.env.GITLAB_HOST = nil

        assert.is_nil(git.match_remote_type('git@codeberg.org:owner/repo.git'))
        assert.is_nil(git.match_remote_type('git@gitlab.example.org:group/repo.git'))
        assert.is_nil(git.match_remote_type('/srv/git/repo.git'))
        assert.is_nil(git.match_remote_type(nil))
    end)
end)
