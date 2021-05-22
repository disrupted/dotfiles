local M = {}

function M.config()
    require('pears').setup(function(conf)
        conf.pair('<', '>')
        conf.preset 'tag_matching'
        conf.on_enter(function(pears_handle)
            if
                vim.fn.pumvisible() == 1
                and vim.fn.complete_info().selected ~= -1
            then
                vim.fn['compe#confirm'] '<CR>'
            else
                pears_handle()
            end
        end)
    end)
end

return M
