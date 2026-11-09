---@type LazeSpec
return {
    'disrupted/neotest-ntf',
    main = 'neotest-ntf',
    module = 'neotest-ntf',
    dependencies = { 'nvim-neotest/neotest' },
    init = function()
        require('conf.neotest.adapters').register('lua', 'neotest-ntf')
    end,
    config = function()
        require('conf.neotest.adapters').attach(require('neotest-ntf'))
    end,
}
