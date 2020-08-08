#!/bin/bash

printHelp() {
	echo -e "\nUsage: $0 -d <domain>"
	exit 1
}

while getopts ":d:" opt;
do
	case "$opt" in
		d) DOMAIN="$OPTARG"
		;;
	esac
done

if [ -z "$DOMAIN" ]
then
	echo "Missing parameter '-d' is required."
	printHelp
else
	openssl req -x509 -out $(echo "${DOMAIN}.crt") -keyout $(echo "${DOMAIN}.key") -newkey rsa:2048 -nodes -sha256 -subj "/CN=${DOMAIN}" -extensions EXT -config <( printf "[dn]\nCN=${DOMAIN}\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:${DOMAIN}\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
fi
