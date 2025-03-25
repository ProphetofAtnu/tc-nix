{ lib, pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    (modulesPath + "/installer/cd-dvd/channel.nix")
  ];

  # 
  boot.blacklistedKernelModules = [ "pinctrl_elkhartlake" ];
  security.sudo.wheelNeedsPassword = false;
  nix.settings.extra-experimental-features = [ "flakes" "nix-command" ];

  environment.etc."install-closure".source =
    "${pkgs.thinClientClosure}/store-paths";

  environment.systemPackages = [ 
    pkgs.unattendedInstaller 
    # I can't seem to get rid of this without causing an issue with the bootloader installation?
    pkgs.thinClientClosure
  ];

  networking.hostName = "nixos-installer";

  services.resolved = {
    enable = true;
    fallbackDns = [ "1.1.1.1" "1.0.0.1" ];
  };

  services.avahi.enable = true;
  services.avahi.publish.addresses = true;

  networking.useDHCP = lib.mkDefault true;

  # Include the closure of dependencies from the parent flake.
  # Final disk image is ~8G, but works offline.
  isoImage.storeContents = [ pkgs.thinClientClosure ];
}
