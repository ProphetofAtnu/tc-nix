# Notes for Others

If you're hacking on this yourself, replace the SSH public key for root in `configuration.nix` and `installer.nix` with your own to allow remote login.

# Layout

This repo is structured to be forked and used for managing and updating a fleet of thin clients in the field. 

## Customization Points

### `prototype.nix`

This is a nixos module that defines shared configuration between the thin clients and the installation media. 

### `base.nix`

Defines the configuration of the base system. This configuration will be inherited by the files in the `./hosts` directory.

### `installer.nix`

Defines the configuration used to create the installation ISO image.

### `./hosts`

`nix` files in this directory will be added to the flake's '#nixosConfigurations' by extending the configuration `#nixosConfigurations.physical`. 

# Run the thin client as a VM

```sh
nix run '.#runVm' # or just "nix run"
```

# Installer

A custom installer for the thin client configuration defined by this flake that supports offline installations.

**Be warned!** It takes an eternity to build and the resulting iso is ~8GiB.

## Build the installer as an ISO

```sh
nix build '.#makeIso'
```

## Using the Installer

### Online

After booting the installer, the command `online-unattended-install` will be available. Needs to be run by root or with sudo.

```sh
online-unattended-install --target /dev/[disk] [--configuration [system in ./hosts]] [-- [optional disko-install flags]]
```

`online-unattended-install` is a simple a wrapper for `disko-install`.

See [disko-install](https://github.com/nix-community/disko/blob/master/docs/disko-install.md).

### Offline

The installer supports offline installation by realizing the configuration `physical` and the disko script used to create the disk layout on the target system.

**NOTE** This is less flexable and assumes a lot about the disk layout of the system in question. In my environment, this will be used on homogenous hardware and isn't a concern, but will likely be a concern for others. Prefer the online installation if possible, as you can directly choose a host configuration and target disk at install time.

```sh
sudo create-partitions # format the drive /dev/sda and mount it to /mnt
sudo install-wrapper # install the #physical configuration to the directory tree '/mnt'
```

After a reboot, the system will likely need to be reconfigured remotely using `nixos-rebuild boot --flake '#the-host' --target-host ssh://physical.local`.
