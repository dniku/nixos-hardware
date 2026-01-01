{
  lib,
  config,
  pkgs,
  ...
}:
let
  # Pull the upstream UCM tree at commit 59bb3c8c (contains the headphone/mic guards)
  # without rebuilding pkgs.alsa-ucm-conf or the wider system.
  ucm2Upstream = pkgs.fetchzip {
    url = "https://github.com/perexg/alsa-ucm-conf/archive/59bb3c8cd016db8f6630c1774884bfb175bb9595.tar.gz";
    hash = "sha256-tV/oEi9NiGXRU0gQMV6CBJhkryCSYIheAbGOIg0v0nQ=";
    stripRoot = true;
  };

  ucm2Patched =
    pkgs.runCommand "alsa-ucm2-fw16-ai300-59bb3c8c" { }
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
  # controls are present. Without this, FW16, which has no physical 3.5mm
  # jack, exposes silent devices.
  systemd.user.services = lib.mkIf config.services.pipewire.enable {
    pipewire.environment.ALSA_CONFIG_UCM2 = lib.mkDefault ucm2Path;
    pipewire-pulse.environment.ALSA_CONFIG_UCM2 = lib.mkDefault ucm2Path;
    wireplumber.environment.ALSA_CONFIG_UCM2 = lib.mkDefault ucm2Path;
  };
}
