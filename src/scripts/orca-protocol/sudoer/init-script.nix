{ config, pkgs, orca_user, share_holders_keys, ... }:
let
  inherit (config.environment.variables) SHARES_FOLDER AIA_FOLDER CERTIFICATE_FOLDER ORCA_FOLDER;
in
''
  set -e
  gpg --import ${share_holders_keys}/* &> /dev/null
  cp /var/lib/acme/.minica/cert.pem ${orca_user.home}/cert.pem
  chown ${orca_user.name} ${orca_user.home}/cert.pem
  mkdir -p ${ORCA_FOLDER}
  mkdir -p ${SHARES_FOLDER}
  mkdir -p ${AIA_FOLDER}
  chown -R ${orca_user.name} ${AIA_FOLDER}
  mkdir -p ${CERTIFICATE_FOLDER}
  chown -R ${orca_user.name} ${CERTIFICATE_FOLDER}

  echo "Cvault : "
  find ${config.services.vault.storagePath} -type f -exec sha256sum -b {} \; | sort -k2 | sha256sum - | cut -d " " -f 1
''
