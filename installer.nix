{ self, lib, pkgs, modulesPath, ... }:
let closureInfo = self.packages.x86_64-linux.closure;
in {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    (modulesPath + "/installer/cd-dvd/channel.nix")
  ];

  # 
  boot.blacklistedKernelModules = [ "pinctrl_elkhartlake" ];
  security.sudo.wheelNeedsPassword = false;
  nix.settings.extra-experimental-features = [ "flakes" "nix-command" ];

  environment.etc."install-closure".source = "${closureInfo}/store-paths";

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "install-nixos-unattended" ''
      set -eux
      exec ${pkgs.disko}/bin/disko-install --flake "${self}#physical" $@
    '')

  ];

  networking.hostName = "nixos-installer";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIDtTbCP2ssWgSwhRxTyAG4+FuTsQLEkh93CaZpq9lQC DEFAULT"
  ];

  services.resolved = {
    enable = true;
    fallbackDns = [ "1.1.1.1" "1.0.0.1" ];
  };

  services.avahi.enable = true;
  services.avahi.publish.addresses = true;

  networking.useDHCP = lib.mkDefault true;

  # Include the closure of dependencies from the parent flake.
  # Final disk image is ~8G, but works offline.
  isoImage.storeContents = [ closureInfo ];
}
