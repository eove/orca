{ config, pkgs, orca_user, ...}:
let
    orcaDir = "${config.services.vault.storagePath}/orca";
in
''
echo "Run initialisation script"
whoami
cp /var/lib/acme/.minica/cert.pem ${orca_user.home}/cert.pem
chown ${orca_user.name} ${orca_user.home}/cert.pem
mkdir -p ${orcaDir}
chown -R ${orca_user.name} ${orcaDir}

echo "Cvault : "
find ${config.services.vault.storagePath} -type f -exec sha256sum -b {} \; | sort -k2 | sha256sum - | cut -d " " -f 1
''
