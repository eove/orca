{ config, pkgs, orca_user, ... }:
let
  inherit (config.environment.variables) SHARES_FOLDER AIA_FOLDER CERTIFICATE_FOLDER ORCA_FOLDER PUBLIC_KEYS_FOLDER OUTPUT_FOLDER;
in
''
  set -e
  gpg --import ${PUBLIC_KEYS_FOLDER}/* &> /dev/null
  cp /var/lib/acme/.minica/cert.pem ${orca_user.home}/cert.pem
  chown ${orca_user.name} ${orca_user.home}/cert.pem
  mkdir -p ${ORCA_FOLDER}
  mkdir -p ${OUTPUT_FOLDER}
  mkdir -p ${SHARES_FOLDER}
  mkdir -p ${AIA_FOLDER}
  mkdir -p ${CERTIFICATE_FOLDER}
  chown -R ${orca_user.name} ${OUTPUT_FOLDER}
''
