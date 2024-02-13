#!/bin/bash
set -eo pipefail
export JELLYFIN_METADATA_DIR_DEFAULT='/var/lib/jellyfin/metadata'
export JELLYFIN_USER_DEFAULT='jellyfin'

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

# look for Jellyfin metadata path
function find-jellyfin-metadata-dir {
    if [[ -n "$JELLYFIN_METADATA_DIR" && -d "$JELLYFIN_METADATA_DIR" ]]; then
        log "Found user-defined JELLYFIN_METADATA_DIR at \"$JELLYFIN_METADATA_DIR\"."
    elif [[ -n "$JELLYFIN_METADATA_DIR" ]]; then
        fail 'ERROR: User-defined JELLYFIN_METADATA_DIR does not exist!' 4
    elif [[ -d "$JELLYFIN_METADATA_DIR_DEFAULT" ]]; then
        log "Found Jellyfin metadata directory at \"$JELLYFIN_METADATA_DIR_DEFAULT\"."
        export JELLYFIN_METADATA_DIR="$JELLYFIN_METADATA_DIR_DEFAULT"
    else
        fail 'ERROR: JELLYFIN_METADATA_DIR not found!' 5
    fi
}

# look for Jellyfin user account
function find-jellyfin-user {
    if [[ -n "$JELLYFIN_USER" ]]; then
        log "Found user-defined JELLYFIN_USER, \"$JELLYFIN_USER\"."
    else
        log "Assuming \"$JELLYFIN_USER_DEFAULT\" for JELLYFIN_USER."
        export JELLYFIN_USER="$JELLYFIN_USER_DEFAULT"
    fi
}

# prepend timestamp and script name to log lines
function log {
    printf "\e[0;30m%s ${0##*/} -\e[0m $*\n" "$(date '+%F %T %Z')"
}

log 'Begin.'
check-deps
check-username
check-password
find-jellyfin-metadata-dir
find-jellyfin-user
export ZAP2XML_CMD="/zap2xml.pl -u '$ZAP2IT_USERNAME' -p '$ZAP2IT_PASSWORD' -U -o /data/tv-guide.xml"

ee "docker run -v '$JELLYFIN_METADATA_DIR/guide:/data' shuaiscott/zap2xml /bin/sh -c \"$ZAP2XML_CMD\""

log 'Done.'
# Copyright © 2024 Zach Butler - https://github.com/kj4ezj/jellyfin-tv-guide
