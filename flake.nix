{
  description = "Flake for generating a thin client";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    disko.url = "github:nix-community/disko";
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

      nixosConfigurations = let
        base = nixpkgs.lib.nixosSystem {
          modules = [
            ./prototype.nix
            ./configuration.nix
            self.nixosModules.thinClient
            { nixpkgs.hostPlatform = nixpkgs.lib.mkDefault "x86_64-linux"; }
          ];
        };
        physical = self.nixosConfigurations.base.extendModules {
          modules = [ disko.nixosModules.disko ./disk-config.nix ];
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
              self.nixosConfigurations.physical.config.system.build.diskoScript
              self.nixosConfigurations.physical.config.system.build.diskoScript.drvPath
              self.nixosConfigurations.physical.pkgs.stdenv.drvPath
              # Why does it have to check python syntax to build the bootloader? ;-;
              # https://github.com/NixOS/nixpkgs/blob/db6ea9d70bffd1041e9fea643d725d48a568ba3c/nixos/modules/system/boot/loader/systemd-boot/systemd-boot.nix#L25
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
