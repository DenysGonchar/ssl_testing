#!/bin/bash
##############################################################
## this script creates Certificate Signing Request (CSR),
## or self-signed certificates (e.g. for root CA)
##############################################################

## default values
ss=false
top_dir=
days=
ext=
extra_params=()

out_file="csr/csr.pem"

function invalid_usage()
{
  echo     "invalid input parameters, correct usage:"
  echo  -n "    create_cert_req.sh [--ss [--days <days>] "
  echo     "[--ext x509_ext_section]] <cert_top_dir>"
  exit 1
}

## process input parameters
[ $# -eq 0 ] && invalid_usage
while [ $# -gt 0 ]; do
  [ "$1" == "--ss"  ]  && { ss=true; shift; continue; }

  [ "$1" == "--days" ] && [ $# -gt 1 ] && "$ss" \
                       && { days="$2"; shift 2; continue; }

  [ "$1" == "--ext" ]  && [ $# -gt 1 ] && "$ss" \
                       && { ext="$2";  shift 2; continue; }

  [ $# -eq 1 ]         && { top_dir="$1"; shift; continue; }

  ## invalid input parameters
  invalid_usage
done

if "$ss"; then
  ## create self-signed certificate
  days="${days:-365}"
  out_file="certs/cert.pem"
  extra_params=("-x509" "-days" "$days" ${ext:+"-extensions" "$ext"})
fi

## input parameters validations
[ -d "$top_dir" ] || { echo "'${top_dir}' - directory doesn't exist"; exit 1; }

## create CSR or self-signed certificate
openssl req -new                                 \
            "${extra_params[@]}"                 \
            -config "${top_dir}/openssl.cfg"     \
            -key    "${top_dir}/private/key.pem" \
            -out    "${top_dir}/${out_file}" || exit 1
            
if "$ss"; then
  cat "${top_dir}/"{"certs/cert","private/key"}".pem" > "${top_dir}/certs/cert_and_key.pem"
fi
