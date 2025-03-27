{ lib, modulesPath, pkgs, ... }:

{
  imports = [
    (modulesPath + "/profiles/minimal.nix")
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nix.settings.extra-experimental-features = [ "flakes" "nix-command" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

   # boot.loader.grub.enable = true;
   # boot.loader.grub.efiSupport = true;
   # boot.loader.grub.device = lib.mkDefault "/dev/sda1";
   # boot.loader.grub.device = lib.mkDefault "nodev";
   # boot.loader.grub.efiInstallAsRemovable = false;
   # boot.loader.efi.canTouchEfiVariables = true;

  boot.blacklistedKernelModules = [ "pinctrl_elkhartlake" ];
  boot.kernelParams = [ "net.ifnames=1" ];

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

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

