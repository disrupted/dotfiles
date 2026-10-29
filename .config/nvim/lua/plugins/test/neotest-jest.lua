---@type LazeSpec
return {
    'haydenmeade/neotest-jest',
    main = 'neotest-jest',
    module = 'neotest-jest',
    dependencies = { 'nvim-neotest/neotest' },
    init = function()
        for _, filetype in ipairs({
            'javascript',
            'typescript',
            'javascriptreact',
            'typescriptreact',
        }) do
            require('conf.neotest.adapters').register(filetype, 'neotest-jest')
        end
    end,
    config = function()
        local project = require('conf.project')
        local opts = {
            -- run from the package manager workspace root like Nx does
            -- the jest config defaults to the nearest jest.config.{ts,js} (i.e. the Nx project)
            jestCommand = function(path)
                local root = project.of(path)
                if not root or root == vim.g.workspace_root then
                    -- nearest node_modules/.bin/jest
                    return require('neotest-jest.jest-util').getJestCommand(path)
                end
                return table.concat(project.exec(root, { 'jest' }), ' ')
            end,
            env = { CI = true },
            cwd = function(path)
                return project.of(path) or vim.g.workspace_root
            end,
        }
        ---@diagnostic disable-next-line: call-non-callable
        local adapter = require('neotest-jest')(opts)
        adapter.name = 'Jest'
        require('conf.neotest.adapters').attach(adapter)
    end,
}
