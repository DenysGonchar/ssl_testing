#!/bin/bash
##############################################
## this script creates directory tree for
## CA/User/Server certificate
##############################################

conf_dir="${CONF_DIR:-./config}"
tool_dir="${TOOL_DIR:-./tools}"

## default values
type=
top_dir=
config= #default value set after input params processing
key_len=2048
crl_uri="URI:http://localhost:8000"

function invalid_usage()
{
  echo "invalid input parameters, correct usage:"
  echo "    create_cert_dir.sh (--ca|--user) <cert_directory>"
  exit 1
}

## process input parameters
[ $# -eq 0 ] && invalid_usage
while [ $# -gt 0 ]; do
  [ "$1" == "--ca"  ]  && [ -z "$type" ] \
                       && { type="ca" key_len=4096; shift; continue; }

  [ "$1" == "--user" ] && [ -z "$type" ] \
                       && { type="user"; shift; continue; }

  [ $# -eq 1 ]         && { top_dir="$1"; shift; continue; }

  ## invalid input parameters
  invalid_usage
done

config="${conf_dir}/${type}.cfg"


## input parameters validations
[ -e "$top_dir" ] && { echo "'${top_dir}' - file exists";         exit 1; }
[ -f "$config"  ] || { echo "'${config}' - config doesn't exist"; exit 1; }

## create directory structure
mkdir -pv "$top_dir"/{private,certs,csr}
cp -v "$config" "${top_dir}/openssl.cfg"
openssl genrsa -out ${top_dir}/private/key.pem "$key_len"
"${tool_dir}/change_config.sh" --cfg "${top_dir}/openssl.cfg" \
                               --set "CN" "$(basename "$top_dir")" || exit 1

if [ "$type" == "ca" ]; then
  mkdir -pv "$top_dir"/{crl,newcerts}
  touch "${top_dir}/index"
  echo 01 > "${top_dir}/serial"
  echo 01 > "${top_dir}/crl/number"
  cp -v "${conf_dir}/x509_ext.cfg" "${top_dir}"
  crl_uri+="/${top_dir#./}/crl/crl.der"
  set_crl_dp=(--set "crlDistributionPoints" "$crl_uri")
  "${tool_dir}/change_config.sh" --cfg "${top_dir}/openssl.cfg" \
                                 --set "dir"    "$top_dir"      \
                                 "${set_crl_dp[@]}" || exit 1
  "${tool_dir}/change_config.sh" --cfg "${top_dir}/x509_ext.cfg" \
                                 "${set_crl_dp[@]}" || exit 1
fi

