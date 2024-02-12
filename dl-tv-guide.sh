#!/bin/bash
set -eo pipefail
echo "$(date '+%F %T %Z') ${0##*/} - Begin."
source ./deps/bin/ee

export ZAP2XML_CMD="/zap2xml.pl -u '$ZAP2IT_USERNAME' -p '$ZAP2IT_PASSWORD' -U -o /data/tv-guide.xml"

ee "docker run -v '$JELLYFIN_METADATA_DIR/guide:/data' shuaiscott/zap2xml /bin/sh -c \"$ZAP2XML_CMD\""

echo "$(date '+%F %T %Z') ${0##*/} - Done."
# Copyright © 2024 Zach Butler - https://github.com/kj4ezj/jellyfin-tv-guide
