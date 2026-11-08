local ntf = require('ntf')
local describe, it = ntf.describe, ntf.it
local assert = ntf.assert

describe('neotest angular', function()
    local angular = require('conf.neotest.angular')
    local ws = '/ws'

    local function test(builder)
        return { test = { builder = builder or angular.builder } }
    end

    local config = {
        projects = {
            lib = { root = 'libs/lib', architect = test() },
            web = { root = 'apps/web', targets = test() },
            legacy = { root = 'apps/legacy', architect = test('@angular/build:karma') },
            app = { root = '', architect = test() },
        },
    }

    it('resolves the innermost unit-test project', function()
        local target = angular._resolve(ws, config, ws .. '/libs/lib/src/a.spec.ts')
        assert.same(
            { workspace = ws, project = 'lib', root = ws .. '/libs/lib' },
            target
        )
        assert.equal(
            'web',
            angular._resolve(ws, config, ws .. '/apps/web/src/a.spec.ts').project
        )
    end)

    it('falls back to a workspace-wide root project', function()
        assert.equal(
            'app',
            angular._resolve(ws, config, ws .. '/src/a.spec.ts').project
        )
        assert.equal(
            'app',
            angular._resolve(ws, config, ws .. '/apps/legacy/a.spec.ts').project
        )
    end)

    it('ignores files outside every project', function()
        local only = { projects = { lib = { root = 'libs/lib', architect = test() } } }
        assert.equal(nil, angular._resolve(ws, only, ws .. '/apps/web/a.spec.ts'))
        assert.equal(nil, angular._resolve(ws, {}, ws .. '/libs/lib/a.spec.ts'))
    end)
end)
