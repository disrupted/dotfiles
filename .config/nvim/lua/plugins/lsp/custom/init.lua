require 'pylance.mason'

local registry = {}
registry['pylance'] = 'pylance.mason'
require('mason-lspconfig.mappings.server').lspconfig_to_package['pylance'] =
    'pylance'

require('lspconfig').pylance.setup {} -- HACK: mason-lspconfig doesn't detect it

return registry
