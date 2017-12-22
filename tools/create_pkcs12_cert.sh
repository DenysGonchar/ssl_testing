#!/bin/bash
##############################################################
## create PKCS12 cert file
##############################################################

## default values
password="${PKCS12_PASSWORD:-passwd}"
ca_opts=()

function invalid_usage()
{
  echo "invalid input parameters, correct usage:"
  echo "    create_pkcs12_cert.sh <cert_directory>"
  exit 1
}

[ $# -ne 1 ] && invalid_usage

req_dir="$1"

[ -f "${req_dir}/certs/cert.pem" ] || { echo "invalid cert directory"; exit 1; }

if [ -f "${req_dir}/certs/ca-chain.pem" ]; then
  ca_opts=(-chain -CAfile "${req_dir}/certs/ca-chain.pem")
fi

openssl pkcs12 -export  "${ca_opts[@]}"                 \
               -out     "${req_dir}/certs/cert.p12"     \
               -in      "${req_dir}/certs/cert.pem"     \
               -inkey   "${req_dir}/private/key.pem"    \
               -passout "pass:${password}"
