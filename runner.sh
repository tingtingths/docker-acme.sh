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

_check_var() {
    declare -a required=($@)
    for i in "${required[@]}"
    do
        if [ -z "${!i}" ]; then echo "${i}"; return 1; fi
    done
}

_exit() {
    _log "Exit Code: ${1}"
    exit ${1}
}

# check variable
no_var=$(_check_var "ACME_HOME")
if [ ! -z "${no_var}" ]; then
    _log "${no_var} is not set!"
    _exit 1
fi

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

# "install" in arguments, trigger installation step
if [[ " ${@} " =~ " install " ]]; then
    no_var=$(_check_var "ACME_HOME" "LE_ACC_EMAIL")
    if [ ! -z "${no_var}" ]; then
        _log "${no_var} is not set! Failed to install acme.sh..."
        _exit 1
    fi

    # run acme --install if home not exists
    if [ ! -f "${ACME_HOME}/acme.sh" ]; then
        _log "Initalizing ACME_HOME: ${ACME_HOME}"

        cd /acme.sh && ./acme.sh --install --nocron --home "${ACME_HOME}" --accountemail "${LE_ACC_EMAIL}"
    else
        _log "ACME_HOME already present: ${ACME_HOME}, skip installation..."
    fi
fi

# "issue" in arguments, trigger issue cert step
if [[ " ${@} " =~ " issue " ]]; then
    no_var=$(_check_var "ACME_HOME" "CERT_DOMAIN" "DEPLOY_HOOK" "CERT_DNS")
    if [ ! -z "${no_var}" ]; then
        _log "${no_var} is not set! Failed to issue new cert..."
        _exit 1
    fi

    # check ACME_HOME installation
    if [ ! -f "${ACME_HOME}/acme.sh" ]; then
        _log "ACME_HOME ${ACME_HOME} does not exist...Please run with \"install\" to install acme.sh."
        _exit 1
    fi

    # if domain not setup, issue and deploy cert for first time
    if [ ! -f "${ACME_HOME}/${CERT_DOMAIN}/${CERT_DOMAIN}.conf" ]; then
        _log "Initalizing domain ${CERT_DOMAIN}..."

        cd ${ACME_HOME} && ./acme.sh --issue --home . -d "${CERT_DOMAIN}" -d "*.${CERT_DOMAIN}" --dns "${CERT_DNS}"
        _log "Cert for domain ${CERT_DOMAIN} initalized, deploying..."
        ./acme.sh --deploy --home . -d "${CERT_DOMAIN}" --deploy-hook ${DEPLOY_HOOK}
    else
        _log "${CERT_DOMAIN} already present: ${ACME_HOME}/${CERT_DOMAIN}/${CERT_DOMAIN}.conf, skip issue new cert..."
    fi
fi

# "renew" in arguments, trigger issue cert step
if [[ " ${@} " =~ " renew " ]]; then
    no_var=$(_check_var "ACME_HOME" "CERT_DOMAIN" "DEPLOY_HOOK")
    if [ ! -z "${no_var}" ]; then
        _log "${no_var} is not set! Failed to issue new cert..."
        _exit 1
    fi

    # check ACME_HOME installation
    if [ ! -f "${ACME_HOME}/acme.sh" ]; then
        _log "ACME_HOME ${ACME_HOME} does not exist...Please run with \"install\" to install acme.sh."
        _exit 1
    fi

    # renew cert
    cd ${ACME_HOME} && RESULT=$(./acme.sh --cron --home .) && echo "${RESULT}"
    # if cert renewed, deploy it
    if ! echo "${RESULT}" | grep -qF "Skipped ${CERT_DOMAIN}" ; then
        _log "${CERT_DOMAIN} renewed, deploying..."
        ./acme.sh --deploy --home . -d "${CERT_DOMAIN}" --deploy-hook ${DEPLOY_HOOK}
    else
        _log "${CERT_DOMAIN} no renew needed..."
    fi
fi

_exit 0