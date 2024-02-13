#!/bin/bash
set -eo pipefail
export GIT_BRANCH=''  # populated by make install
export GIT_VERSION='' # populated by make install
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
        if id -u "$JELLYFIN_USER" >/dev/null 2>&1; then
            log "Found user-defined JELLYFIN_USER, \"$JELLYFIN_USER\"."
        else
            fail "ERROR: User-defined JELLYFIN_USER \"$JELLYFIN_USER\" does not exist!" 6
        fi
    elif id -u "$JELLYFIN_USER_DEFAULT" >/dev/null 2>&1; then
        log "Found Jellyfin user \"$JELLYFIN_USER_DEFAULT\"."
        export JELLYFIN_USER="$JELLYFIN_USER_DEFAULT"
    else
        fail 'ERROR: No "jellyfin" user account found on this computer.' 7
    fi
}

# populate the git branch and version
function git-metadata {
    if [[ -z "$GIT_BRANCH" ]]; then
        GIT_BRANCH="$(git branch --show-current)"
        export GIT_BRANCH
    fi
    if [[ -z "$GIT_VERSION" ]]; then
        SCRIPT_PATH="$(readlink -f "$0")"
        SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
        pushd "$SCRIPT_DIR" >/dev/null
        GIT_VERSION="$(git describe --tags --exact-match 2>/dev/null || git rev-parse HEAD)"
        export GIT_VERSION
        popd >/dev/null
    fi
}

# return the git uri
function git-uri {
    echo "https://github.com/kj4ezj/jellyfin-tv-guide/tree/$GIT_VERSION"
}

# prepend timestamp and script name to log lines
function log {
    printf "\e[0;30m%s ${0##*/} -\e[0m $*\n" "$(date '+%F %T %Z')"
}

# print help and exit
function log-help-and-exit {
    echo 'Help flag not written yet, please see online documentation:'
    README_URI="$(git-uri | tr -d '\n\r')"
    echo "$README_URI/README.md"
    echo
    echo 'If you open an issue on GitHub, please include this info:'
    log-version-and-exit
}

# print the timestamp the guide was last downloaded
function log-last-run-time {
    if [[ ! -f "$1" ]]; then
        log 'Last Guide Download: Never'
    else
        CURRENT_UNIX_TIME="$(date '+%s')"
        LAST_MOD_UNIX_TIME="$(stat -c '%Y' "$1")"
        HOURS_SINCE="$(( (CURRENT_UNIX_TIME - LAST_MOD_UNIX_TIME) / 3600 ))"
        if (( HOURS_SINCE > 48 )); then
            TIME_SINCE_STR="$(( HOURS_SINCE / 24 )) days ago"
        else
            TIME_SINCE_STR="$HOURS_SINCE hours ago"
        fi
        log "Last Guide Download: $(date -d "@$LAST_MOD_UNIX_TIME" '+%F %T %Z') ($TIME_SINCE_STR)"
    fi
}

# print script version and other info
function log-version-and-exit {
    echo "kj4ezj/jellyfin-tv-guide:$GIT_VERSION on $GIT_BRANCH"
    echo
    git-uri
    readlink -f "$0"
    echo 'Copyright © 2024 Zach Butler'
    echo 'MIT License'
    exit 0
}

# main
git-metadata
# parse args
for RAW_ARG in "$@"; do
    ARG="$(echo "$RAW_ARG" | tr -d '-')"
    if [[ "$ARG" == 'h' || "$ARG" == 'help' || "$ARG" == '?' ]]; then
        log-help-and-exit
    elif [[ "$ARG" == 'v' || "$ARG" == 'version' ]]; then
        log-version-and-exit
    fi
done
log 'Begin.'
# check prerequisites
check-deps
check-username
check-password
find-jellyfin-metadata-dir
find-jellyfin-user
# download guide data
log-last-run-time "$JELLYFIN_METADATA_DIR/guide/tv-guide.xml"
export ZAP2XML_CMD="/zap2xml.pl -u '$ZAP2IT_USERNAME' -p '$ZAP2IT_PASSWORD' -U -o /data/tv-guide.xml"
ee "docker run -v '$JELLYFIN_METADATA_DIR/guide:/data' shuaiscott/zap2xml /bin/sh -c \"$ZAP2XML_CMD\""
# fix permissions
ee "chmod -x '$JELLYFIN_METADATA_DIR/guide/tv-guide.xml'"
ee "chown -R '$JELLYFIN_USER:$JELLYFIN_USER' '$JELLYFIN_METADATA_DIR/guide'"

log 'Done.'

# https://github.com/kj4ezj/jellyfin-tv-guide

# MIT License
#
# Copyright (c) 2024 Zach Butler
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
