{ pkgs, flake, ... }:

pkgs.writeShellApplication {
  name = "create-partitions";
  text = flake.nixosConfigurations.physical.config.system.build.diskoScript;
}

