#########################################################################
## global variables
#########################################################################
export CONF_DIR = ./config
export TOOL_DIR = ./tools

CertDir   ?= certificates
CertGraph  = $(CertDir)/graph
VPATH      = $(CertDir)

SepLine = _____________________________________

#########################################################################
## graph functions
#########################################################################
define add_graph_line
  sed -i '$$s~^~  $1\n~' "$(CertGraph)"
endef

define add_cert
  @[ -f "$(CertGraph)" ] || echo "digraph certs {\n}" > "$(CertGraph)"
  @$(call add_graph_line,$(subst /,_,$1) [label="$1"])
  @[ -z "$2" ] || $(call add_graph_line,$2 -> $(subst /,_,$1))
endef

define add_description
  @[ -f "$(CertGraph)" ] && sed -i 's/^\s*$1\s*\[.*label\s*=\s*"[^"]*/\0$2/' "$(CertGraph)"
endef

#########################################################################
## cert functions
#########################################################################
define create_selfsigned_cert
  @echo "\n$(SepLine)\ncreate_selfsigned_cert\n$(SepLine)\n"
  # cert name  : '$1'
  # cert type  : '$2'
  # extra opts : '$3'
  @echo "$(SepLine)\n"
  @$(TOOL_DIR)/create_cert_dir.sh "--$2" "$(CertDir)/$1"
  @$(TOOL_DIR)/create_cert_req.sh --ss $3 "$(CertDir)/$1"
  @$(call add_cert,$1)
endef

define create_ca_signed_cert
  @echo "\n$(SepLine)\ncreate_ca_signed_cert\n$(SepLine)\n"
  # cert name     : '$1'
  # cert type     : '$2'
  # CA cert name  : '$3'
  # x509v3 ext.   : '$4'
  # extra CA opts : '$5'
  @echo "$(SepLine)\n"
  @$(TOOL_DIR)/create_cert_dir.sh "--$2" "$(CertDir)/$1"
  @$(TOOL_DIR)/create_cert_req.sh "$(CertDir)/$1"
  @$(TOOL_DIR)/sign_cert.sh --ca  "$(CertDir)/$(notdir $3)" \
                            --req "$(CertDir)/$1"           \
                            --ext "$4"                      \
                            $5
  @$(call add_cert,$1,$3)
endef

define revoke_cert
  @echo "\n$(SepLine)\nrevoke_cert\n$(SepLine)\n"
  # cert name     : '$1'
  # CA cert name  : '$2'
  @echo "$(SepLine)\n"
  @$(TOOL_DIR)/generate_crl.sh --revoke "$(CertDir)/$1" "$(CertDir)/$(notdir $2)"
  $(call add_description,$1,\\n[revoked])
endef

ifeq ($(OCSP),true)
  define create_ocsp_cert
    @echo "\n$(SepLine)\ncreate_ocsp_cert\n$(SepLine)\n"
    # cert name : '$1'
    # ocsp uri  : '$2'
    @echo "$(SepLine)\n"
    $(call add_description,$1,\\n[ocsp $2])
    @$(TOOL_DIR)/change_config.sh --cfg "$(CertDir)/$1/x509_ext.cfg" \
                                  --set authorityInfoAccess "OCSP;URI:http://$2"
    @$(TOOL_DIR)/create_cert_dir.sh --user "$(CertDir)/$1/ocsp/"
    @$(TOOL_DIR)/change_config.sh --cfg "$(CertDir)/$1/ocsp/openssl.cfg" \
                                  --set CN "$2"
    @$(TOOL_DIR)/create_cert_req.sh "$(CertDir)/$1/ocsp/"
    @$(TOOL_DIR)/sign_cert.sh --ca  "$(CertDir)/$1"      \
                              --req "$(CertDir)/$1/ocsp" \
                              --ext ocsp
  endef
endif

define clean_all
  rm -rf "$(CertDir)"
endef

define clean
  cd "$(CertDir)"; rm -rf $1; cd -
endef

