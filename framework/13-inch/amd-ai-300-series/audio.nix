{
  lib,
  config,
  pkgs,
  ...
}:
let
  # Pull the upstream UCM tree at commit e9720b09 (contains the headphone/mic guards)
  # without rebuilding pkgs.alsa-ucm-conf or the wider system.
  ucm2Upstream = pkgs.fetchzip {
    url = "https://github.com/alsa-project/alsa-ucm-conf/archive/e9720b098ff5289e9bdd9ebd34a87870f0b87be6.tar.gz";
    hash = "sha256-Gub+iREkwkeIwnqz1VM39rACqbFeDNk6b4prD7+Z7AU=";
    stripRoot = true;
  };

  ucm2Patched =
    pkgs.runCommand "alsa-ucm2-fw13-ai300-e9720b09" { }
      ''
        set -euo pipefail
        mkdir -p "$out/share/alsa"
        cp -a "${ucm2Upstream}/ucm2" "$out/share/alsa/"
      '';

  ucm2Path = "${ucm2Patched}/share/alsa/ucm2";
in
{
  # Point ALSA / PipeWire / WirePlumber at the patched UCM profiles so the
  # Headphones and HDA capture devices are only created when the relevant
  # controls are present.
  systemd.user.services = lib.mkIf config.services.pipewire.enable {
    pipewire.environment.ALSA_CONFIG_UCM2 = lib.mkDefault ucm2Path;
    pipewire-pulse.environment.ALSA_CONFIG_UCM2 = lib.mkDefault ucm2Path;
    wireplumber.environment.ALSA_CONFIG_UCM2 = lib.mkDefault ucm2Path;
  };
}
