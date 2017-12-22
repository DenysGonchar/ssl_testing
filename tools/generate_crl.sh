#!/bin/bash
##############################################################
## this script generate Certificate Revocation List for CA
##############################################################

## default values
ca_dir=
cert_dir=
cert_file=

function invalid_usage()
{
  echo "invalid input parameters, correct usage:"
  echo "    generate_crl.sh [--revoke <cert_top_dir>] <ca_top_dir>"
  exit 1
}

## process input parameters
[ $# -eq 0 ] && invalid_usage
while [ $# -gt 0 ]; do
  [ "$1" == "--revoke" -a $# -gt 1 ] && { cert_dir="$2"; shift 2; continue; }
  [ $# -eq 1 ]                       && { ca_dir="$1";   shift;   continue; }
  ## invalid input parameters
  invalid_usage
done

## input parameters validations
[ -f "${ca_dir}/x509_ext.cfg" ] || { echo "'${ca_dir}' - is not valid CA directory";  exit 1; }

## revoke certificate
if [ -n "$cert_dir" ]; then
  cert_file="${cert_dir}/certs/cert.pem"
  [ -f "$cert_file" ] || { echo "'${cert_file}' - cert file doesn't exist"; exit 1; }
  openssl ca -revoke "$cert_file" \
             -config "${ca_dir}/openssl.cfg"
fi

## recreate Certificate Revocation List
openssl ca -gencrl                    \
           -config "${ca_dir}/openssl.cfg" \
           -out    "${ca_dir}/crl/crl.pem" || exit 1

openssl crl -inform  PEM -in  "${ca_dir}/crl/crl.pem" \
            -outform DER -out "${ca_dir}/crl/crl.der" 
