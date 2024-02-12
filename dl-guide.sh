#!/bin/bash
set -eo pipefail

# check for dependencies
function check-deps {
    if [[ -f ./deps/bin/ee ]]; then
        log 'Found "./deps/bin/ee".'
        source ./deps/bin/ee
    elif ee >/dev/null 2>&1; then
        log 'Found "ee" (echo-eval) in the environment.'
    else
        fail 'FATAL: Missing dependency "ee" (echo-eval)!' 127
    fi
}

# check for zap2it password
function check-password {
    if [[ -n "$ZAP2IT_PASSWORD" ]]; then
        log "Found zap2it password with $(printf '%s' "$ZAP2IT_PASSWORD" | wc -c) characters."
    else
        fail 'ERROR: No zap2it password found!' 3
    fi
}

# check for zap2it username
function check-username {
    if [[ -n "$ZAP2IT_USERNAME" ]]; then
        log "Found zap2it username: $ZAP2IT_USERNAME"
    else
        fail 'ERROR: No zap2it username found!' 2
    fi
}

# fail with a useful error
function fail {
    log "\e[1;31m$1\e[0m"
    log 'Documentation: https://github.com/kj4ezj/jellyfin-tv-guide'
    log 'Exiting...'
    exit "${2:-1}"
}

# prepend timestamp and script name to log lines
function log {
    printf "\e[0;30m%s ${0##*/} -\e[0m $*\n" "$(date '+%F %T %Z')"
}

log 'Begin.'
check-deps
check-username
check-password
export ZAP2XML_CMD="/zap2xml.pl -u '$ZAP2IT_USERNAME' -p '$ZAP2IT_PASSWORD' -U -o /data/tv-guide.xml"

ee "docker run -v '$JELLYFIN_METADATA_DIR/guide:/data' shuaiscott/zap2xml /bin/sh -c \"$ZAP2XML_CMD\""

log 'Done.'
# Copyright © 2024 Zach Butler - https://github.com/kj4ezj/jellyfin-tv-guide
