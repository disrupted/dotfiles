local ntf = require('ntf')
local describe, it = ntf.describe, ntf.it
local before_each, after_each = ntf.before_each, ntf.after_each
local assert = ntf.assert

describe('forge provider detection', function()
    local forge
    local gitlab_host
    local provider_override

    before_each(function()
        package.loaded['conf.forge'] = nil
        package.loaded['git'] = nil
        forge = require('conf.forge')
        gitlab_host = vim.env.GITLAB_HOST
        provider_override = vim.g.forge_provider
        vim.g.forge_provider = nil
    end)

    after_each(function()
        vim.env.GITLAB_HOST = gitlab_host
        vim.g.forge_provider = provider_override
        package.loaded['conf.forge'] = nil
        package.loaded['git'] = nil
    end)

    it('selects the GitHub provider', function()
        local provider = forge.detect('git@github.com:owner/repo.git')

        assert.no.is_nil(provider)
        assert.equal('github', provider.id)
        assert.equal('PR', provider.noun)
    end)

    it('selects the GitLab provider', function()
        vim.env.GITLAB_HOST = 'https://git.example.org/'

        local provider = forge.detect('git@git.example.org:group/repo.git')

        assert.no.is_nil(provider)
        assert.equal('gitlab', provider.id)
        assert.equal('MR', provider.noun)
    end)

    it('returns nil for unsupported remotes', function()
        vim.env.GITLAB_HOST = nil

        assert.is_nil(forge.detect('git@codeberg.org:owner/repo.git'))
    end)

    it('honors the explicit provider override', function()
        vim.g.forge_provider = 'gitlab'

        local provider = forge.detect('git@github.com:owner/repo.git')

        assert.no.is_nil(provider)
        assert.equal('gitlab', provider.id)
    end)
end)
