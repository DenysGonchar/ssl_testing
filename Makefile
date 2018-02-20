
include tools/tools.mk

#########################################################################
## general targets
#########################################################################
.PHONY: all clean
.DEFAULT: all

all: valid revoked expired selfsigned unknown

clean:
	$(call clean_all)


#########################################################################
## valid certificates
#########################################################################
ValidCerts = root_ca         \
             intermediate_ca \
             server          \
             client

.PHONY: valid clean_valid

valid: | $(ValidCerts)

clean_valid:
	$(call clean,$(ValidCerts))

root_ca:
	$(call create_selfsigned_cert,$@,ca)
	$(call create_ocsp_cert,$@,localhost:8001)

intermediate_ca: | root_ca
	$(call create_ca_signed_cert,$@,ca,$|,ca)
	$(call create_ocsp_cert,$@,localhost:8002)

client server: | intermediate_ca
	$(call create_ca_signed_cert,$@,user,$|,$@)

#########################################################################
## revoked certificates
#########################################################################
RevokedCerts = revoked_intermediate_ca \
               revoked_client          \
               revoked_ca_client

.PHONY: revoked clean_revoked

revoked: | $(RevokedCerts)

clean_revoked:
	$(call clean,$(RevokedCerts))

revoked_intermediate_ca: | root_ca
	$(call create_ca_signed_cert,$@,ca,$|,ca)
	$(call revoke_cert,$@,$|)

revoked_client: | intermediate_ca
	$(call create_ca_signed_cert,$@,user,$|,client)
	$(call revoke_cert,$@,$|)

revoked_ca_client: | revoked_intermediate_ca
	$(call create_ca_signed_cert,$@,user,$|,client)


#########################################################################
## expired certificates
#########################################################################
ExpiredCerts = expired_intermediate_ca \
               expired_client          \
               expired_ca_client

#datetime format YYMMDDHHMMSSZ
ExipedDates = -startdate 010101000000Z -enddate 010102000000Z

.PHONY: expired

expired: | $(ExpiredCerts)

clean_expired:
	$(call clean,$(ExpiredCerts))

expired_intermediate_ca: | root_ca
	$(call create_ca_signed_cert,$@,ca,$|,ca,$(ExipedDates))
	$(call add_description,$@,\\n[expired])

expired_client: | intermediate_ca
	$(call create_ca_signed_cert,$@,user,$|,client,$(ExipedDates))
	$(call add_description,$@,\\n[expired])

expired_ca_client: | expired_intermediate_ca
	$(call create_ca_signed_cert,$@,user,$|,client)

#########################################################################
## selfsigned certificates
#########################################################################
SelfsignedCerts = selfsigned_server \
                  selfsigned_client 

.PHONY: selfsigned

selfsigned: | $(SelfsignedCerts)

clean_selfsigned:
	$(call clean,$(SelfsignedCerts))

selfsigned_server:
	$(call create_selfsigned_cert,$@,user,--ext server)

selfsigned_client:
	$(call create_selfsigned_cert,$@,user,--ext client)

#########################################################################
## unknown CA certificates
#########################################################################
UnknownCaCerts = unknown_ca \
                 unknown_ca_client

.PHONY: unknown

unknown: | $(UnknownCaCerts)

clean_unknown:
	$(call clean,$(UnknownCaCerts))

unknown_ca:
	$(call create_selfsigned_cert,$@,ca)

unknown_ca_client: | unknown_ca
	$(call create_ca_signed_cert,$@,user,$|,client)

