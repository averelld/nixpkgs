{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.x2goserver;
in {
  options.programs.x2goserver.enable = mkEnableOption "x2goserver";

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.x2goserver ];
    users.extraGroups.x2gouser = {};
    users.extraUsers.x2gouser = {
      createHome = true;
      home = "/var/lib/x2go";
      group = "x2gouser";
    };
    users.extraGroups.x2goprint = {};

    security.wrappers.x2gosqliteWrapper = {
      source = "${pkgs.x2goserver}/lib/x2go/libx2go-server-db-sqlite3-wrapper";
      owner = "root";
      group = "x2gouser";
      setgid = true;
    };
    security.wrappers.x2goprintWrapper = {
      source = "${pkgs.x2goserver}/bin/x2goprint";
      owner = "root";
      group = "x2goprint";
      setgid = true;
    };
    # x2goclient sends SSH commands with preset PATH set to
    # "/usr/local/bin;/usr/bin;/bin". Since we cannot filter arbitrary ssh
    # commands, we have to make the following executables available.
    system.activationScripts.x2goserver = with pkgs; ''
      mkdir -p /usr/local/bin
      for exe in ${x2goserver}/bin/x2go*
      do
        ln -sf $exe /usr/local/bin/
      done
      for util in \
        ${xorg.xrandr}/bin/xrandr ${xorg.xmodmap}/bin/xmodmap \
        ${utillinux}/bin/setsid ${gawk}/bin/awk ${gnused}/bin/sed \
        ${coreutils}/bin/cp ${coreutils}/bin/chmod
      do
        ln -sf $util /usr/local/bin/
      done
      if [ ! -f /var/lib/x2go/x2go_sessions ]
      then
        ${x2goserver}/bin/x2godbadmin --createdb
      fi
    '';
  };
}
