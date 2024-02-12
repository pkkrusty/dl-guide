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
        log '\e[1;31mFATAL: Missing dependency "ee" (echo-eval)!\e[0m'
        log 'See documentation: https://github.com/kj4ezj/jellyfin-tv-guide'
        exit 127
    fi
}

# prepend timestamp and script name to log lines
function log {
    printf "\e[0;30m%s ${0##*/} -\e[0m $*\n" "$(date '+%F %T %Z')"
}

log 'Begin.'
check-deps
export ZAP2XML_CMD="/zap2xml.pl -u '$ZAP2IT_USERNAME' -p '$ZAP2IT_PASSWORD' -U -o /data/tv-guide.xml"

ee "docker run -v '$JELLYFIN_METADATA_DIR/guide:/data' shuaiscott/zap2xml /bin/sh -c \"$ZAP2XML_CMD\""

log 'Done.'
# Copyright © 2024 Zach Butler - https://github.com/kj4ezj/jellyfin-tv-guide
