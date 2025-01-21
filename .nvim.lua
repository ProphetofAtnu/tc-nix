local nvim_lsp = require('lspconfig')

nvim_lsp.nixd.setup {
  settings = {
    nixd = {
      nixpkgs = {
        expr = "import <nixpkgs> { }",
      },
      options = {
        nixos = {
          expr = '(builtins.getFlake (toString ./.)).nixosConfigurations.vm.options'
        },
        home_manager = {
          expr = '(builtins.getFlake (toString ./.)).nixosConfigurations.vm.options.home-manager.users.type.getSubOptions []'
        }
      }
    }
  }
}
