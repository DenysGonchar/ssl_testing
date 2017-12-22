#!/bin/bash
##############################################################
## this script signs Certificate Signing Request (CSR)
##############################################################

tool_dir="${TOOL_DIR:-./tools}"

## default values
ca_dir=
req_dir=
req_file=
x509_ext=
out_file=
extra_params=()

function invalid_usage()
{
  echo    "invalid input parameters, correct usage:"
  echo -n "    sign_cert.sh --ca <ca_top_dir> --req <req_top_dir> "
  echo    "--ext <x509_ext_section> [EXTRA_CA_OPTS...]"
  exit 1
}

## process input parameters
[ $# -eq 0 ] && invalid_usage
while true; do
  [ "$1" == "--ca"  ] && [ $# -gt 1 ] && { ca_dir="$2";   shift 2; continue; }
  [ "$1" == "--req" ] && [ $# -gt 1 ] && { req_dir="$2";  shift 2; continue; }
  [ "$1" == "--ext" ] && [ $# -gt 1 ] && { x509_ext="$2"; shift 2; continue; }
  break
done

req_file="${req_dir}/csr/csr.pem"
out_file="${req_dir}/certs/cert.pem"

extra_params=("$@")

## input parameters validations
[ -f "${ca_dir}/x509_ext.cfg" ] || { echo "'${ca_dir}' - is not valid CA directory";    exit 1; }
[ -f "$req_file" ]              || { echo "'${req_file}' - request file doesn't exist"; exit 1; }
[ -z "$x509_ext" ]              && { echo "'--ext' option is mandatory";                exit 1; }

## sign certificate
yes | openssl ca -config     "${ca_dir}/openssl.cfg"  \
                 -extfile    "${ca_dir}/x509_ext.cfg" \
                 -extensions "$x509_ext"              \
                 -in         "$req_file"              \
                 -out        "$out_file"              \
                 "${extra_params[@]}" || exit 1

cat "${req_dir}/"{"certs/cert","private/key"}".pem" > "${req_dir}/certs/cert_and_key.pem"

## recreate Certificate Revocation List
"${tool_dir}/generate_crl.sh" "${ca_dir}" || exit 1

## create CA chain
ca_chain="certs/ca-chain.pem"
openssl x509 -in  "${ca_dir}/certs/cert.pem" \
             -out "${req_dir}/${ca_chain}"   \
             -outform PEM  || exit 1
             
[ ! -f "${ca_dir}/${ca_chain}" ] || cat "${ca_dir}/${ca_chain}" >>"${req_dir}/${ca_chain}"

