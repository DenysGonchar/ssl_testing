#!/bin/bash
##############################################################
## this script verifies certificate
##############################################################

## default values
ocsp=
crl_file=
crl_check=
crl_opts=()
ca_chain_opts=()
ss_cert=false
cert=

function invalid_usage()
{
  echo "invalid input parameters, correct usage:"
  echo "    verify_cert.sh [--ocsp] [--crl|--crl_file <pem_crl_file>] <cert_directory>"
  exit 1
}

## process input parameters
[ $# -eq 0 ] && invalid_usage
while [ $# -gt 0 ]; do
  [ "$1" == "--ocsp" ]      && { ocsp=true; shift; continue; }

  [ "$1" == "--crl" ]       && [ -z "$crl_file" ] \
                            && { crl_check=true; shift; continue; }
                       
  [ "$1" == "--crl_file" ]  && [ -z "$crl_check" -a $# -gt 1 ] \
                            && { crl_file="$2"; shift 2; continue; }

  [ $# -eq 1 ]              && { cert="$1"; shift; continue; }

  ## invalid input parameters
  invalid_usage
done

cert_file="${cert}/certs/cert.pem"
ca_chain="${cert}/certs/ca-chain.pem"

[ -f "$cert_file" ] || { echo "'$cert_file' - certificate file doesn't exist"; exit 1; }

if [ -f "$ca_chain" ]; then
  ca_chain_opts=(-CAfile "$ca_chain")
elif [ -n "$crl_file" -o -n "$crl_check" -o -n "$ocsp" ]; then
  echo "CRL/OCSP validation is not applicable to self-signed certificate"; exit 1
elif [ -f "${cert}/x509_ext.cfg" ]; then
  #sef-signed CA certificate
  ca_chain_opts+=(-trusted "$cert_file" -check_ss_sig)
else
  echo "self-signed user (server/client) certificate"; exit;
fi

if [ -n "$crl_file" ]; then
  crl_opts=(-CRLfile "$crl_file" -crl_check)
elif [ -n "$crl_check" ]; then
  crl_opts=(-crl_download -crl_check_all)
fi

if [ -n "$ocsp" ]; then
  uri="$(openssl x509 -ocsp_uri -noout -in "$cert_file")"
  [ -z "$uri" ] && { echo "no ocsp uri specified for the certificate"; exit 1; }
  openssl ocsp "${ca_chain_opts[@]}" -issuer "$ca_chain" -text  -url "$uri" -cert "$cert_file"
fi

#echo openssl verify "${ca_chain_opts[@]}" "${crl_opts[@]}" "$cert_file"
openssl verify "${ca_chain_opts[@]}" "${crl_opts[@]}" "$cert_file"

