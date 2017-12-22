#!/bin/bash
##############################################################
## this script starts OCSP server
##############################################################

function invalid_usage()
{
  echo "invalid input parameters, correct usage:"
  echo "    start_oscp_server.sh <ca_cert_directory>"
  exit 1
}

[ $# -ne 1 ] && invalid_usage

[ -d "$1/ocsp" ] || { echo "there's no ocsp cert"; exit 1; }

ocsp_cert="$1/ocsp/certs/cert.pem"
uri="$(openssl x509 -noout -subject -in "$ocsp_cert" | sed -En "s/.*CN=(\S*).*/\1/p")"
openssl ocsp -text                                 \
             -port    "$uri"                       \
             -index   "$1/index"                   \
             -CA      "$1/ocsp/certs/ca-chain.pem" \
             -rkey    "$1/ocsp/private/key.pem"    \
             -rsigner "$ocsp_cert"
