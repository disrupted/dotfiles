---@type LazeSpec
return {
    'marilari88/neotest-vitest',
    main = 'neotest-vitest',
    module = 'neotest-vitest',
    dependencies = { 'nvim-neotest/neotest' },
    init = function()
        for _, filetype in ipairs({
            'javascript',
            'typescript',
            'javascriptreact',
            'typescriptreact',
        }) do
            require('conf.neotest.adapters').register(filetype, 'neotest-vitest')
        end
    end,
    config = function()
        local project = require('conf.project')
        local runner = require('conf.neotest.runner')
        local opts = {
            -- spell out `run` instead of relying on CI=true to leave watch mode
            vitestCommand = function(path)
                local angular = require('conf.neotest.angular')
                local target = angular.target(path)
                if target then
                    return angular.command(target)
                end
                local root = project.of(path)
                if not root or root == vim.g.workspace_root then
                    -- nearest node_modules/.bin/vitest
                    return runner.bin('vitest', path) .. ' run'
                end
                return table.concat(project.exec(root, { 'vitest', 'run' }), ' ')
            end,
            env = { CI = true },
            cwd = function(path)
                return project.of(path) or vim.g.workspace_root
            end,
            is_test_file = runner.is_test_file('vitest'),
        }
        ---@diagnostic disable-next-line: call-non-callable
        local adapter = require('neotest-vitest')(opts)
        adapter.name = 'Vitest'
        require('conf.neotest.adapters').attach(adapter)
    end,
}
