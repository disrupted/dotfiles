local ntf = require('ntf')
local describe, it = ntf.describe, ntf.it
local assert = ntf.assert

describe('files picker directory scope', function()
    local files = require('conf.snacks.files')

    it('has no constraint without directories', function()
        assert.is_nil(files.glob({}))
    end)

    it('matches everything below a single directory', function()
        assert.equal('backend/packages/core/**', files.glob({ 'backend/packages/core' }))
    end)

    it('combines several directories into one brace glob (OR, not AND)', function()
        assert.equal(
            '{backend/packages/core,frontend/libs/shared}/**',
            files.glob({ 'backend/packages/core', 'frontend/libs/shared' })
        )
    end)
end)
