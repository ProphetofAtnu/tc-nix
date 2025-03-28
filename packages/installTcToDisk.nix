{ pkgs, flake, ... }:

pkgs.writeShellApplication {
  name = "install-wrapper";
  text = ''
    nixos-install --system ${flake.nixosConfigurations.physical.config.system.build.toplevel} --option substitute false --no-root-password
  '';
}
