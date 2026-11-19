---@type doze.Spec
return {
    src = 'https://github.com/disrupted/neotest-ntf',
    dependencies = { 'neotest' },
    init = function()
        require('conf.neotest.adapters').register('lua', 'neotest-ntf')
    end,
    config = function()
        require('conf.neotest.adapters').attach(require('neotest-ntf'))
    end,
}
