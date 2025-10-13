{ config, pkgs, orca_user, share_holders_keys,...}:
let
    orcaDir = "${config.services.vault.storagePath}/orca";
    env = config.orca.environment-target;
in
''
gpg --import ${share_holders_keys}/* &> /dev/null
cp /var/lib/acme/.minica/cert.pem ${orca_user.home}/cert.pem
chown ${orca_user.name} ${orca_user.home}/cert.pem
mkdir -p ${orcaDir}
#TODO move shares to a root only folder
export SHARES_FOLDER="${orcaDir}/shares/${env}"
mkdir -p $SHARES_FOLDER
export AIA_FOLDER="${orcaDir}/aia/${env}"
mkdir -p $AIA_FOLDER
export CERTIFICATE_FOLDER="${orcaDir}/certificates/${env}"
mkdir -p $CERTIFICATE_FOLDER
chown -R ${orca_user.name} ${orcaDir}

echo "Cvault : "
find ${config.services.vault.storagePath} -type f -exec sha256sum -b {} \; | sort -k2 | sha256sum - | cut -d " " -f 1
''
