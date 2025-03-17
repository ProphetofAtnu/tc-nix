{
  description = "Flake for generating a thin client";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, disko, ... }@inputs:
    let 
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
      {
      formatter.${system} = pkgs.nixfmt-classic;
      homeManagerModules.openboxConfig = import ./modules/openboxConfigure.nix;

      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = {
              self = self;
            };
            home-manager.sharedModules = [ self.homeManagerModules.openboxConfig ]; 
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.thinclient = import ./homes/home.nix;
          }
          { nixpkgs.hostPlatform = "x86_64-linux"; }
        ];
      };
    };
}
