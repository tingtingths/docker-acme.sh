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

deploy() {
    no_var=$(_check_var "ACME_HOME" "DEPLOY_HOOK")
    if [ ! -z "${no_var}" ]; then
        _log "${no_var} is not set! Cannot deploy..."
        _exit 1
    fi

    # check ACME_HOME installation
    if [ ! -f "${ACME_HOME}/acme.sh" ]; then
        _log "ACME_HOME ${ACME_HOME} does not exist...Please run with \"install\" to install acme.sh."
        _exit 1
    fi

    _log "Deploying ${CERT_DOMAIN}..."
    "${ACME_HOME}/acme.sh" --insecure --deploy --home "${ACME_HOME}" -d "${CERT_DOMAIN}" --deploy-hook ${DEPLOY_HOOK}
}

# check variable
no_var=$(_check_var "ACME_HOME")
if [ ! -z "${no_var}" ]; then
    _log "${no_var} is not set!"
    _exit 1
fi

_log "ACME RUNNER CONFIG ==========================================="
_log "ACME_HOME: ${ACME_HOME}"
_log "LE_ACC_EMAIL: ${LE_ACC_EMAIL}"
_log "CERT_DOMAIN: ${CERT_DOMAIN}"
_log "CERT_DNS: ${CERT_DNS}"
_log "DEPLOY_HOOK: ${DEPLOY_HOOK}"
_log "=========================================== ACME RUNNER CONFIG"
_log ""
_log ""

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
        /acme.sh/acme.sh --install --nocron --home "${ACME_HOME}" --accountemail "${LE_ACC_EMAIL}"
        "${ACME_HOME}/acme.sh" --upgrade --home "${ACME_HOME}"
    else
        _log "ACME_HOME already present: ${ACME_HOME}, skip installation..."
    fi
fi

# "upgrade" in arguments, trigger installation step
if [[ " ${@} " =~ " upgrade " ]]; then
    no_var=$(_check_var "ACME_HOME")
    if [ ! -z "${no_var}" ]; then
        _log "${no_var} is not set! Failed to install acme.sh..."
        _exit 1
    fi

    # check ACME_HOME installation
    if [ ! -f "${ACME_HOME}/acme.sh" ]; then
        _log "ACME_HOME ${ACME_HOME} does not exist...Please run with \"install\" to install acme.sh."
        _exit 1
    fi

    _log "acme.sh version..."
    "${ACME_HOME}/acme.sh" --home "${ACME_HOME}" --version
    _log "Upgrading acme.sh..."
    "${ACME_HOME}/acme.sh" --home "${ACME_HOME}" --upgrade
fi

# "issue" in arguments, trigger issue cert step
if [[ " ${@} " =~ " issue " ]]; then
    no_var=$(_check_var "ACME_HOME" "CERT_DOMAIN" "CERT_DNS")
    if [ ! -z "${no_var}" ]; then
        _log "${no_var} is not set! Cannot issue new cert..."
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
        "${ACME_HOME}/acme.sh" --issue --home "${ACME_HOME}" -d "${CERT_DOMAIN}" -d "*.${CERT_DOMAIN}" --dns "${CERT_DNS}"
        _log "Cert for domain ${CERT_DOMAIN} initalized, deploying..."
        deploy
    else
        _log "${CERT_DOMAIN} already present: ${ACME_HOME}/${CERT_DOMAIN}/${CERT_DOMAIN}.conf, skip issue new cert..."
    fi
fi

# "renew" in arguments, trigger issue cert step
if [[ " ${@} " =~ " renew " ]]; then
    no_var=$(_check_var "ACME_HOME" "CERT_DOMAIN")
    if [ ! -z "${no_var}" ]; then
        _log "${no_var} is not set! Cannot renew cert..."
        _exit 1
    fi

    # check ACME_HOME installation
    if [ ! -f "${ACME_HOME}/acme.sh" ]; then
        _log "ACME_HOME ${ACME_HOME} does not exist...Please run with \"install\" to install acme.sh."
        _exit 1
    fi

    # renew cert
    RESULT=$("${ACME_HOME}/acme.sh" -r --home "${ACME_HOME}" -d "${CERT_DOMAIN}" | sed 's/\r//g') && echo "${RESULT}"
    # if cert renewed, deploy it
    if ! echo "${RESULT}" | grep -qiF "Skip" ; then
        _log "${CERT_DOMAIN} renewed, deploying..."
        deploy
    else
        _log "${CERT_DOMAIN} no renewal needed..."
    fi
fi

if [[ " ${@} " =~ " deploy " ]]; then
    deploy
fi

_exit 0
