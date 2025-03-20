{
  description = "Flake for generating a thin client";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
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

      nixosConfigurations.base = nixpkgs.lib.nixosSystem {
        specialArgs = {
          home-manager = home-manager;
          flake = self;
        };
        modules = [
          ./configuration.nix
          self.nixosModules.thinClientUser
          { nixpkgs.hostPlatform = nixpkgs.lib.mkDefault "x86_64-linux"; }
        ];
      };

      nixosConfigurations.physical = self.nixosConfigurations.base.extendModules {

        modules = [
          # {
          #   virtualisation.vmVariantWithDisko = {
          #     virtualisation.fileSystems."/persist".neededForBoot = true;
          #   };
          # }
          disko.nixosModules.disko
          ./disk-config.nix
          ./hardware-configuration.nix
        ];


      };

      # nixosConfigurations.physical = nixpkgs.lib.nixosSystem {
      #   specialArgs = {
      #     home-manager = home-manager;
      #     flake = self;
      #   };
      #   modules = [
      #     ./configuration.nix
      #     disko.nixosModules.disko
      #     ./disk-config.nix
      #     self.nixosModules.thinClientUser
      #     ./hardware-configuration.nix
      #     { nixpkgs.hostPlatform = "x86_64-linux"; }
      #   ];
      # };


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

      packages.x86_64-linux.bincache = pkgs.mkBinaryCache {
        rootPaths = [self.packages.x86_64-linux.closure];
      };

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
