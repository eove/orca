{ config, ... }:
''
  sudo systemctl stop ${config.systemd.services.vault.name}
''
