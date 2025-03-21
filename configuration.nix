{ lib, modulesPath, pkgs, ... }:

{
  imports = [ (modulesPath + "/profiles/minimal.nix") ];

  nix.settings.extra-experimental-features = [ "flakes" "nix-command" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.blacklistedKernelModules = [ "pinctrl_elkhartlake" ];

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIDtTbCP2ssWgSwhRxTyAG4+FuTsQLEkh93CaZpq9lQC DEFAULT"
  ];

  networking.useDHCP = lib.mkDefault true;

  environment.systemPackages = with pkgs; [ vim wget ];

  services.xserver.displayManager.gdm = {
    enable = true;
    autoSuspend = false;
    autoLogin.delay = 10;
  };

  thinClient.enable = true;
  thinClient.allowPowerControl = true;

  system.stateVersion = "24.11";
}

