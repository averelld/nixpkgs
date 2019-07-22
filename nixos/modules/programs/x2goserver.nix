{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.x2goserver;

  x2goServerConf = pkgs.writeText "x2goserver.conf" ''
    [superenicer]
    # enable the SupeReNicer code in x2gocleansessions, this will renice suspended sessions to nice level 19
    # and renice them to level 0 if the session becomes marked as running again...
    enable=no
  '';

  x2goAgentOptions = pkgs.writeText "x2goagent.options" ''
    X2GO_NXOPTIONS=""
    X2GO_NXAGENT_DEFAULT_OPTIONS="${concatStringsSep " " cfg.nxagentDefaultOptions}"
  '';

in {
  options.programs.x2goserver = {
    enable = mkEnableOption "x2goserver";

    superenicer = {
      enable = mkEnableOption "superenicer" // {
        description = ''
          Enables the SupeReNicer code in x2gocleansessions, this will renice
          suspended sessions to nice level 19 and renice them to level 0 if the
          session becomes marked as running again
        '';
      };
    };

    nxagentDefaultOptions = mkOption {
      type = types.listOf types.str;
      default = [ "-extension GLX" "-nolisten tcp" ];
      example = [ "-extension GLX" "-nolisten tcp" ];
      description = ''
        List of default nx agent options.
      '';
    };
  };

  config = mkIf cfg.enable {

    environment.systemPackages = [ pkgs.x2goserver ];

    users.groups.x2go = {};
    users.users.x2go = {
      home = "/var/lib/x2go/db";
      group = "x2go";
    };

    security.wrappers.x2gosqliteWrapper = {
      source = "${pkgs.x2goserver}/lib/x2go/libx2go-server-db-sqlite3-wrapper.pl";
      owner = "x2go";
      group = "x2go";
      setgid = true;
    };
    security.wrappers.x2goprintWrapper = {
      source = "${pkgs.x2goserver}/bin/x2goprint";
      owner = "x2go";
      group = "x2go";
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
      mkdir -p /var/lib/x2go/conf
      cp -r ${x2goserver}/etc/x2go/* /var/lib/x2go/conf/
      ln -sf ${x2goServerConf} /var/lib/x2go/conf/x2goserver.conf
      ln -sf ${x2goAgentOptions} /var/lib/x2go/conf/x2goagent.options
      if [ ! -f /var/lib/x2go/db/x2go_sessions ]
      then
        ${x2goserver}/bin/x2godbadmin --createdb
      fi
    '';

    systemd.tmpfiles.rules = [
      "d /var/lib/x2go/ - x2go x2go - -"
      "d /var/lib/x2go/db - x2go x2go - -"
      "d /var/lib/x2go/conf - x2go x2go - -"
      "d /run/x2go 0755 x2go x2go - -"
    ];

    systemd.services.x2goserver = {
      description = "X2Go Server Daemon";
      wantedBy = [ "multi-user.target" ];
      unitConfig.Documentation = "man:x2goserver.conf(5)";
      serviceConfig = {
        Type = "forking";
        ExecStart = "${pkgs.x2goserver}/bin/x2gocleansessions";
        PIDFile = "/run/x2go/x2goserver.pid";
        User = "x2go";
        Group = "x2go";
        RuntimeDirectory = "x2go";
        StateDirectory = "x2go";
      };
    };

    # https://bugs.x2go.org/cgi-bin/bugreport.cgi?bug=276
    security.sudo.extraConfig = ''
      Defaults  env_keep+=QT_GRAPHICSSYSTEM
    '';
  };
}
