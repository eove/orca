If the offline CA has been compromised, excluding the offline root CA, the following script should be run in a IN65 workflow to revoke the intermediate offline CA's certificate:
`templates/authenticated/revoke-certificate.sh`

You should then regenerate all children CAs (but not end device certificates)

If the online CA has been compromised, the following script should be run in a IN65 workflow to revoke the offline CA's certificate:
`templates/authenticated/revoke-certificate.sh`

You should then regenerate all children online CAs (but not end device certificates)
