describe('workspace test-file detection', function()
    local workspace

    before_each(function()
        package.loaded['conf.workspace'] = nil
        workspace = require 'conf.workspace'
    end)

    after_each(function()
        package.loaded['conf.workspace'] = nil
    end)

    it('matches common test naming patterns', function()
        local test_paths = {
            'test_foo.py',
            'foo_test.py',
            'tests/foo.py',
            'src/tests/foo.py',
            'TestAdapter.java',
            'AdapterTest.java',
            'foo_spec.lua',
            'foo.spec.lua',
            'foo-tests.go',
            'foo\\tests\\bar.py',
        }

        for _, path in ipairs(test_paths) do
            assert.is_true(workspace.is_test_file(path), path)
        end
    end)

    it('avoids false positives', function()
        local non_test_paths = {
            'neotest.lua',
            'conftest.py',
            'latest_results.txt',
            'src/mytests/foo.py',
            'speculative.lua',
            'attest.go',
        }

        for _, path in ipairs(non_test_paths) do
            assert.is_false(workspace.is_test_file(path), path)
        end
    end)
end)
