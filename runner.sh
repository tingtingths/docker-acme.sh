#!/usr/bin/env bash
# acme.sh runner script for Synology DSM.
# The script will
#   1. install acme.sh
#   2. issue new certificate if not already done
#   3. renew and deploy to Synology DSM if necessary
# Best to run this script with a scheduler with reasonable interval, e.g. weekly.

_log() {
    echo ${@:2} "[$(date '+%Y-%m-%d %H:%M:%S')] ACME RUNNER | ${1}"
}

# check variable
declare -a required=("ACME_HOME" "DEPLOY_HOOK" "LE_ACC_EMAIL" "CERT_DOMAIN" "CERT_DNS")
for i in "${required[@]}"
do
    if [ -z "${!i}" ]; then echo "${i} is not set!!!"; exit 1; fi
done

# debug message
if [ true ]; then
    _log "ACME RUNNER CONFIG ==========================================="
    _log "ACME_HOME: ${ACME_HOME}"
    _log "LE_ACC_EMAIL: ${LE_ACC_EMAIL}"
    _log "CERT_DOMAIN: ${CERT_DOMAIN}"
    _log "CERT_DNS: ${CERT_DNS}"
    _log "DEPLOY_HOOK: ${DEPLOY_HOOK}"
    if [ "dns_cf" = "${CERT_DNS}" ]; then
        _log "Cloudflare DNS:"
        _log "\tCF_Key: ${CF_Key}" -e
        _log "\tCF_Email: ${CF_Email}" -e
        _log "\tCF_Token: ${CF_Token}" -e
        _log "\tCF_Account_ID: ${CF_Account_ID}" -e
        _log "\tCF_Zone_ID: ${CF_Zone_ID}" -e
    fi
    if [ "synology_dsm" = "${DEPLOY_HOOK}" ]; then
        _log "Deploy Hook synology_dsm:"
        _log "\tSYNO_Username: ${SYNO_Username}" -e
        _log "\tSYNO_Password: ${SYNO_Password}" -e
        _log "\tSYNO_Scheme: ${SYNO_Scheme}" -e
        _log "\tSYNO_Hostname: ${SYNO_Hostname}" -e
        _log "\tSYNO_Port: ${SYNO_Port}" -e
        _log "\tSYNO_DID: ${SYNO_DID}" -e
    fi
    _log "=========================================== ACME RUNNER CONFIG"
    _log ""
    _log ""
fi

# run acme --install if home not exists
if [ ! -d "${ACME_HOME}" ]; then
    _log "Initalizing ACME_HOME: ${ACME_HOME}..."
    cd /acme.sh && ./acme.sh --install --nocron --home "${ACME_HOME}" --accountemail "${LE_ACC_EMAIL}"
fi

# if domain not setup, issue and deploy cert for first time
if [ ! -f "${ACME_HOME}/${CERT_DOMAIN}/${CERT_DOMAIN}.conf" ]; then
    _log "Initalizing domain ${CERT_DOMAIN}"
    cd ${ACME_HOME} && ./acme.sh --issue --home . -d "${CERT_DOMAIN}" --dns "${CERT_DNS}"
    _log "Cert for domain ${CERT_DOMAIN} initalized, deploying..."
    ./acme.sh --deploy --home . -d "${CERT_DOMAIN}" --deploy-hook ${DEPLOY_HOOK}
fi

# renew cert
cd ${ACME_HOME} && RESULT=$(./acme.sh --cron --home .) && echo "${RESULT}"
# if cert renewed, deploy it
if ! echo "${RESULT}" | grep -qF "Skipped ${CERT_DOMAIN}" ; then
    _log "Cert for domain ${CERT_DOMAIN} renewed, deploying..."
    ./acme.sh --deploy --home . -d "${CERT_DOMAIN}" --deploy-hook ${DEPLOY_HOOK}
fi

_log "Completed..."