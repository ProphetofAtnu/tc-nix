{ pkgs, flake, ... }:

pkgs.writeShellApplication {
  name = "online-unattended-install";
  runtimeInputs = [ pkgs.disko flake ];

  text = ''
    OPTIONS=$(getopt -o 'ht:c:' --long 'help,target:,configuration:' -n 'online-unattended-install' -- "$@")

    eval set -- "$OPTIONS"

    TARGETDISK=""
    TARGETCONF="physical"

    while [ $# -gt 0 ]; do
      case "$1" in
        '-h'|'--help') 
          cat <<-EOF

    unattended-install usage:

      --help | -h -- print usage text
      --target [disk] | -t [disk] -- The disk to apply the configuration to
      --configuration [name] | -c [name] -- The name of the nixosConfiguration to apply (default: physical)

    EOF
          exit 0

          ;;
        '-t'|'--target')
          TARGETDISK=$2
          shift 2;
          ;;
        '-c'|'--configuration')
          TARGETCONF=$2
          shift 2;
          ;;
        '--')
          shift
          break
          ;;
        *)
          shift
          ;;
      esac
    done
    exec ${pkgs.disko}/bin/disko-install --flake "${flake}#$TARGETCONF" --disk main "$TARGETDISK" "$@"
  '';

}
