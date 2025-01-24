{ config, lib, nixpkgs, modulesPath, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.blacklistedKernelModules = [ "pinctrl_elkhartlake" ];
  security.sudo.wheelNeedsPassword = false;

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.thinclient = {
    isNormalUser = true;
    hashedPassword = "";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIDtTbCP2ssWgSwhRxTyAG4+FuTsQLEkh93CaZpq9lQC DEFAULT"
  ];

  services.xserver.enable = true;

  services.xserver.windowManager.openbox.enable = true;

  services.xserver.displayManager.gdm = {
    enable = true;
    autoSuspend = false;
    autoLogin.delay = 10;
  };

  services.displayManager = {
    defaultSession = "none+openbox";
    autoLogin = {
      user = "thinclient";
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    remmina
    obconf
    xorg.xhost
  ];

  services.openssh.enable = true;


  system.stateVersion = "24.11";

}

