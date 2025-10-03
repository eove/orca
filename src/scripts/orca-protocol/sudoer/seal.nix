{ config, ... }:
''
  systemctl stop ${config.systemd.services.vault.name}
''
