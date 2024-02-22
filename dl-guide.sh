#!/bin/bash
set -eo pipefail
export GIT_BRANCH=''  # populated by make install
export GIT_ORIGIN=''  # populated by make install
export GIT_VERSION='' # populated by make install
export JELLYFIN_METADATA_DIR_DEFAULT='/var/lib/jellyfin/metadata'
export OUTPUT_FILE_DEFAULT='tv-guide.xml'

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
    log 'Documentation: https://github.com/kj4ezj/dl-guide'
    log 'Exiting...'
    exit "${2:-1}"
}

# look for other user account
function find-chown-user {
    if [[ -n "$CHOWN_USER" ]]; then
        if id -u "$CHOWN_USER" >/dev/null 2>&1; then
            log "Found user-defined CHOWN_USER, \"$CHOWN_USER\"."
        else
            fail "ERROR: User-defined CHOWN_USER \"$CHOWN_USER\" does not exist!" 6
        fi
    else
        log 'Not changing ownership of output file.'
    fi
}

# look for output path
function find-output-dir {
    # parse user input and look for directory
    if [[ -n "$OUTPUT" && -d "$OUTPUT" ]]; then
        log "Found user-defined output dir at \"$OUTPUT\"."
        OUTPUT_DIR="$(readlink -f "$OUTPUT")"
        OUTPUT_FILE="$OUTPUT_FILE_DEFAULT"
    elif [[ -n "$OUTPUT" ]]; then
        log "Found user-defined output: \"$OUTPUT\""
        OUTPUT_DIR="$(get-dir "$OUTPUT")"
        OUTPUT_FILE="$(get-filename "$OUTPUT")"
        if [[ "$OUTPUT_DIR" == "$OUTPUT_FILE" ]]; then
            OUTPUT_DIR="$(readlink -f .)"
        fi
        if [[ -d "$OUTPUT_DIR" ]]; then
            OUTPUT_DIR="$(readlink -f "$OUTPUT_DIR")"
            log "Folder exists at \"$OUTPUT_DIR\"."
        else
            fail "ERROR: Folder does not exist at \"$OUTPUT_DIR\"!" 5
        fi
        if [[ -z "${OUTPUT_FILE//./}" ]]; then
            OUTPUT_FILE="$OUTPUT_FILE_DEFAULT"
        fi
    elif [[ -d "$JELLYFIN_METADATA_DIR_DEFAULT" ]]; then
        log "Found Jellyfin metadata directory at \"$JELLYFIN_METADATA_DIR_DEFAULT\", using that."
        OUTPUT_DIR="$JELLYFIN_METADATA_DIR_DEFAULT"
        OUTPUT_FILE="$OUTPUT_FILE_DEFAULT"
    else
        fail 'ERROR: No output path given!' 4
    fi
    # construct full path
    OUTPUT_PATH="$OUTPUT_DIR/$OUTPUT_FILE"
    log "Using output path: \"$OUTPUT_PATH\""
    export OUTPUT_DIR OUTPUT_FILE OUTPUT_PATH
}

# get directory from path
function get-dir {
    echo "${1%/*}"
}

# get file from path
function get-filename {
    echo "${1##*/}"
}

# populate the git branch, origin, and version
function git-metadata {
    # branch
    if [[ -z "$GIT_BRANCH" ]]; then
        GIT_BRANCH="$(git branch --show-current)"
        export GIT_BRANCH
    fi
    # remote origin
    if [[ -z "$GIT_ORIGIN" ]]; then
        GIT_ORIGIN="$(git remote get-url origin)"
    fi
    ORIGIN="$(echo "$GIT_ORIGIN" | sed 's/[.]git//' | sed -E 's_(git@|https?://)__' | tr ':' '/')"
    GIT_REPO="${ORIGIN#*/}"
    export GIT_ORIGIN GIT_REPO
    # version string
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
    ORIGIN="$(echo "$GIT_ORIGIN" | sed 's/[.]git//' | sed -E 's_(git@|https?://)__' | tr ':' '/')"
    echo "https://$ORIGIN/tree/$GIT_VERSION"
}

# prepend timestamp and script name to log lines
function log {
    printf "\e[0;30m%s ${0##*/} -\e[0m $*\n" "$(date '+%F %T %Z')"
}

# print help and exit
function log-help-and-exit {
    echo '
                                ############
                                # dl-guide #
                                ############

Download TV guide metadata, then set the correct file permissions and ownership.

$ dl-guide [OPTIONS]

[OPTIONS] - command-line arguments to change behavior
    -c, --chown, --owner, --change-owner <USER>
        Change the ownership of the output file to the specified user. If not
        specified, the ownership will not be changed.
            Requires script be run with "sudo -E" or root privileges.

    -h, --help, -?
        Print this help message and exit.

    -o, --output, --output-dir, --output-file, --path <PATH>
        Specify the output directory or file. If a directory is given, the
        default file name (tv-guide.xml) will be used. If no output file,
        folder, or path is given, then the default Jellyfin metadata directory
        will be used if it exists.

    -u, --username, --zap2it-username <USERNAME>
        Specify the zap2it username.

    -v, --version
        Print the script version and debug info.

[VARIABLES] - configurable environment variables
    CHOWN_USER
        The user to change the ownership of the output file to. Equivalent to
        "--chown".

    OUTPUT
        The output directory or file. Equivalent to "--output".

    ZAP2IT_PASSWORD (required)
        The password for your zap2it account.

    ZAP2IT_USERNAME
        The username for your zap2it account. Equivalent to "--username".

[NOTES]
Arguments take precedence over environment variables.

A zap2it account is required to use this script. The password cannot be provided
as a command-line argument because it would be visible to other programs via the
process list and shell history.

This script runs a docker container, so docker engine is required and the script
must have permission to run containers.

[DOCUMENTATION]'
    README_URI="$(git-uri | tr -d '\n\r')"
    echo "$README_URI/README.md"
    echo
    echo 'Copyright © 2024 Zach Butler'
    echo 'MIT License'
    exit 0
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
    echo "$GIT_REPO:$GIT_VERSION on $GIT_BRANCH"
    echo
    readlink -f "$0"
    git-uri
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        printf 'Running on %s %s with ' "$NAME" "$VERSION"
    elif [[ "$(uname)" == 'Darwin' ]]; then
        printf 'Running on %s %s with ' "$(sw_vers -productName)" "$(sw_vers -productVersion)"
    elif [[ "$(uname)" == 'Linux' ]]; then
        printf 'Running on Linux %s with ' "$(uname -r)"
    else
        echo 'Running on unidentified OS with '
    fi
    bash --version | head -1
    echo 'Copyright © 2024 Zach Butler'
    echo 'MIT License'
    exit 0
}

# main
git-metadata
# parse args
for (( i=1; i <= $#; i++)); do
    ARG="$(echo "${!i}" | tr -d '-')"
    if [[ "$(echo "$ARG" | grep -icP '^(c|chown|(change)?owner(ship)?)$')" == '1' ]]; then
        i="$(( i+1 ))"
        CHOWN_USER="${!i}"
    elif [[ "$ARG" == 'h' || "$ARG" == 'help' || "$ARG" == '?' ]]; then
        log-help-and-exit
    elif [[ "$(echo "$ARG" | grep -icP '^(o|out(put)?(dir|file|folder|path)?)$')" == '1' ]]; then
        i="$(( i+1 ))"
        OUTPUT="${!i}"
    elif [[ "$(echo "$ARG" | grep -icP '^(p|(zap2it)?password)$')" == '1' ]]; then
        fail 'ERROR: It is not safe to provide your password as an argument!' 8
    elif [[ "$(echo "$ARG" | grep -icP '^(u|(zap2it)?user(name)?)$')" == '1' ]]; then
        i="$(( i+1 ))"
        ZAP2IT_USERNAME="${!i}"
    elif [[ "$ARG" == 'v' || "$ARG" == 'version' ]]; then
        log-version-and-exit
    fi
done
log 'Begin.'
# check prerequisites
check-deps
check-username
check-password
find-chown-user
find-output-dir
# download guide data
log-last-run-time "$OUTPUT_PATH"
ZAP2XML_CMD="/zap2xml.pl -u '$ZAP2IT_USERNAME' -p '$ZAP2IT_PASSWORD' -U -o '/data/$OUTPUT_FILE'"
ee "docker run -v '$OUTPUT_DIR:/data' kj4ezj/zap2xml /bin/sh -c \"$ZAP2XML_CMD\""
# fix permissions
ee "chmod -x '$OUTPUT_PATH'"
if [[ -n "$CHOWN_USER" ]]; then
    ee "chown '$CHOWN_USER:$CHOWN_USER' '$OUTPUT_PATH'"
fi

log 'Done.'

# https://github.com/kj4ezj/dl-guide

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
