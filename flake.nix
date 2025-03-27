{
  description = "Flake for generating a thin client";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko, ... }:
    let
      lib = nixpkgs.lib;
      supportedSystems =
        [ "x86_64-linux" "i686-linux" "aarch64-linux" "riscv64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      formatter =
        forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-classic);

      nixosModules.thinClient = import ./modules/nixos/thinClient.nix;
      diskoConfigurations.client = import ./disk-config.nix;

      nixosConfigurations = let
        base = nixpkgs.lib.nixosSystem {
          modules = [
            ./prototype.nix
            ./configuration.nix
            self.nixosModules.thinClient
            disko.nixosModules.disko 
            { nixpkgs.hostPlatform = nixpkgs.lib.mkDefault "x86_64-linux"; }
          ];
        };
        physical = self.nixosConfigurations.base.extendModules {
          modules = [ ./disk-config.nix ];
        };
        installer = nixpkgs.lib.nixosSystem {
          specialArgs.self = self;
          modules = [
            ./prototype.nix
            ./installer.nix
            { nixpkgs.hostPlatform = nixpkgs.lib.mkDefault "x86_64-linux"; }
            {
              nixpkgs.overlays = [
                (final: super: {
                  thinClientClosure =
                    self.packages.${super.stdenv.hostPlatform.system}.closure;
                  unattendedInstaller =
                    self.packages.${super.stdenv.hostPlatform.system}.unattendedInstaller;

                  ### *** BIG HACK HERE DO NOT USE ***
                  makePartitions = super.writeShellApplication {
                    name = "create-partitions";
                    text = self.nixosConfigurations.physical.config.system.build.diskoScript;
                  };

                  installToDisk = super.writeShellApplication {
                    name = "install-wrapper";
                    text = ''
                      nixos-install --system ${self.nixosConfigurations.physical.config.system.build.toplevel} --no-root-password
                    '';
                  };
                })
              ];
            }
          ];
        };
      in lib.mergeAttrs { inherit base physical installer; }
      (builtins.listToAttrs (map (module: {
        name = "${lib.removeSuffix ".nix" module}";
        value = physical.extendModules { modules = [ ./hosts/${module} ]; };
      }) (builtins.filter (lib.hasSuffix ".nix")
        (builtins.attrNames (builtins.readDir ./hosts)))));

      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          closure = let
            dependencies = [
              self.nixosConfigurations.physical.config.system.build.toplevel
              self.nixosConfigurations.physical.config.system.build.installBootLoader
              # self.nixosConfigurations.physical.config.system.build.diskoScript
              self.nixosConfigurations.physical.pkgs.perlPackages.ConfigIniFiles
              self.nixosConfigurations.physical.pkgs.perlPackages.FileSlurp
              (self.nixosConfigurations.physical.pkgs.closureInfo {
                rootPaths = [ ];
              }).drvPath
            ] ++ builtins.map (i: i.outPath) (builtins.attrValues self.inputs);
          in nixpkgs.legacyPackages.${system}.closureInfo {
            rootPaths = dependencies;
          };

          unattendedInstaller =
            pkgs.callPackage ./packages/unattendedInstaller.nix {
              flake = self;
            };

          bincache = pkgs.mkBinaryCache {
            rootPaths = [ self.packages.${system}.closure ];
          };

          makeIso =
            self.nixosConfigurations.installer.config.system.build.isoImage;

          runVm =
            self.nixosConfigurations.physical.config.system.build.vmWithDisko;

          default = self.packages.${system}.runVm;

        });

    };
}
