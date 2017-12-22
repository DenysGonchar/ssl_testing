#!/bin/bash
##############################################################
## this script signs Certificate Signing Request (CSR)
##############################################################

## default values
cfg_file=
sed_cmd=

function invalid_usage()
{
  echo    "invalid input parameters, correct usage:"
  echo -n "    change_config.sh --cfg <config_file> "
  echo    "[--rm <option_name> | --set <option_name> <value> ...]"
  exit 1
}

tmp=()

function add_set_cmd()
{
  [[ "$1" =~ ^[a-zA-Z0-9_]*$ ]] || { echo "'$1' - invalid option"; exit 1; }
  tmp+=("s/^[#[:space:]]*$1[=[:space:]].*/$1 = ${2//\//\\/}/")
}

function add_rm_cmd()
{
  [[ "$1" =~ ^[a-zA-Z0-9_]*$ ]] || { echo "'$1' - invalid option"; exit 1; }
  tmp+=("s/^\s*$1/#&/")
}

## process input parameters
[ $# -eq 0 ] && invalid_usage
while [ $# -gt 0 ]; do
  [ "$1" == "--cfg" ] && [ $# -gt 1 ] && { cfg_file="$2";     shift 2; continue; }
  [ "$1" == "--rm"  ] && [ $# -gt 1 ] && { add_rm_cmd $2;     shift 2; continue; }
  [ "$1" == "--set" ] && [ $# -gt 2 ] && { add_set_cmd $2 $3; shift 3; continue; }
  invalid_usage
done

sed_cmd="$(IFS=";"; echo "${tmp[*]}")"

## input parameters validations
[ -f "$cfg_file" ]    || { echo "'${cfg_file}' - config file doesn't exist"; exit 1; }

sed -i "$sed_cmd" "$cfg_file"

