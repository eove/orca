{ config, ... }:
''
  set -e
  systemctl stop ${config.systemd.services.vault.name}
''
