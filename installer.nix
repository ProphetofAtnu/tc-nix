{ self, config, lib, pkgs, modulesPath, ... }:
let closureInfo = self.packages.x86_64-linux.closure;
in {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    (modulesPath + "/installer/cd-dvd/channel.nix")
  ];

  # configure proprietary drivers
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  boot.blacklistedKernelModules = [ "pinctrl_elkhartlake" ];
  security.sudo.wheelNeedsPassword = false;

  environment.etc."install-closure".source = "${closureInfo}/store-paths";

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "install-nixos-unattended" ''
      set -eux
      # Replace "/dev/disk/by-id/some-disk-id" with your actual disk ID
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

  isoImage.storeContents = [ closureInfo ];
  isoImage.squashfsCompression = "zstd -Xcompression-level 15";

}
