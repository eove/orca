{ config, recordDir, orca_user,... }:
''
RECORD_DIR=${recordDir}
cp /var/lib/acme/.minica/cert.pem ${orca_user.home}/cert.pem
chown ${orca_user.name} ${orca_user.home}/cert.pem
mkdir -p $RECORD_DIR
chown -R ${orca_user.name} ${config.services.vault.storagePath}/orca
''
