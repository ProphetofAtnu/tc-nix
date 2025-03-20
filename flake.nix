{
  description = "Flake for generating a thin client";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, disko, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      formatter.${system} = pkgs.nixfmt-classic;

      homeManagerModules.openboxConfig =
        import ./modules/hm/openboxConfigure.nix;

      nixosModules.thinClientUser = import ./modules/nixos/thinClientUser.nix;

      # nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
      #   specialArgs = {
      #     home-manager = home-manager;
      #     flake = self;
      #   };
      #   modules = [
      #     ./configuration.nix
      #     disko.nixosModules.disko
      #     self.nixosModules.thinClientUser
      #     { nixpkgs.hostPlatform = "x86_64-linux"; }
      #   ];
      # };

      nixosConfigurations.physical = nixpkgs.lib.nixosSystem {
        specialArgs = {
          home-manager = home-manager;
          flake = self;
        };
        modules = [
          ./configuration.nix
          disko.nixosModules.disko
          ./disk-config.nix
          self.nixosModules.thinClientUser
          ./hardware-configuration.nix
          { nixpkgs.hostPlatform = "x86_64-linux"; }
        ];
      };

      packages.x86_64-linux.closure = let
        dependencies = [
          self.nixosConfigurations.physical.config.system.build.toplevel
          self.nixosConfigurations.physical.config.system.build.diskoScript
          self.nixosConfigurations.physical.config.system.build.diskoScript.drvPath
          self.nixosConfigurations.physical.pkgs.stdenv.drvPath
          self.nixosConfigurations.physical.pkgs.perlPackages.ConfigIniFiles
          self.nixosConfigurations.physical.pkgs.perlPackages.FileSlurp
          (self.nixosConfigurations.physical.pkgs.closureInfo {
            rootPaths = [ ];
          }).drvPath
        ] ++ builtins.map (i: i.outPath) (builtins.attrValues self.inputs);
      in pkgs.closureInfo { rootPaths = dependencies; };

      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        specialArgs.self = self;
        modules =
          [ ./installer.nix 
            { nixpkgs.hostPlatform = "x86_64-linux"; } 
          ];
      };

      packages.x86_64-linux.makeIso = self.nixosConfigurations.installer.config.system.build.isoImage;
    };
}
