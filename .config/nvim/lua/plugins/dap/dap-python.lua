---@type LazeSpec
return {
    'mfussenegger/nvim-dap-python',
    main = 'dap-python',
    module = 'dap-python',
    dependencies = { 'mfussenegger/nvim-dap' },
    init = function()
        require('conf.dap.adapters').register('python', 'dap-python')
    end,
    config = function()
        local opts = {
            include_configs = false,
            console = 'internalConsole',
        }
        local py = require 'dap-python'
        local function debugpy_python()
            local roots = {
                vim.env.MISE_DATA_DIR,
                vim.fs.joinpath(vim.env.HOME or '', '.local/share/mise'),
            }
            for _, root in ipairs(roots) do
                if root and root ~= '' then
                    local matches = vim.fn.glob(
                        vim.fs.joinpath(
                            root,
                            'installs/pipx-debugpy/*/debugpy/bin/python'
                        ),
                        true,
                        true
                    )
                    if matches[1] then
                        return matches[1]
                    end
                end
            end
            return 'python'
        end

        py.setup(debugpy_python(), opts)
        py.test_runner = 'pytest'
        local dap = require 'dap'
        local configs = dap.configurations.python or {}
        dap.configurations.python = configs
        table.insert(configs, {
            type = 'python',
            request = 'launch',
            name = 'Launch file',
            program = '${file}',
            console = opts.console,
            pythonPath = opts.pythonPath,
        })
        table.insert(configs, {
            type = 'python',
            request = 'launch',
            name = 'Launch file with arguments',
            program = '${file}',
            args = function()
                local args_string = vim.fn.input 'Arguments: '
                return vim.split(args_string, ' +')
            end,
            console = opts.console,
            pythonPath = opts.pythonPath,
        })
        table.insert(configs, {
            type = 'python',
            request = 'launch',
            name = 'Launch main.py',
            program = function()
                return './main.py'
            end,
            pythonPath = opts.pythonPath,
        })
        table.insert(configs, {
            type = 'python',
            request = 'launch',
            name = 'FastAPI module',
            module = 'uvicorn',
            args = function()
                return {
                    vim.fn.input('FastAPI app module > ', 'main:app', 'file'),
                    -- '--reload', -- doesn't work
                    '--use-colors',
                }
            end,
            pythonPath = 'python',
            console = 'integratedTerminal',
        })
        table.insert(configs, {
            type = 'python',
            request = 'attach',
            name = 'Attach remote',
            mode = 'remote',
            host = function()
                local host = vim.fn.input 'Host [127.0.0.1]: '
                return host ~= '' and host or '127.0.0.1'
            end,
            port = function()
                return tonumber(vim.fn.input 'Port [5678]: ') or 5678
            end,
            pathMappings = {
                {
                    localRoot = function()
                        return vim.fn.input(
                            'Local code folder > ',
                            vim.uv.cwd(),
                            'file'
                        )
                    end,
                    remoteRoot = function()
                        return vim.fn.input(
                            'Container code folder > ',
                            '/',
                            'file'
                        )
                    end,
                },
            },
        })
    end,
}
