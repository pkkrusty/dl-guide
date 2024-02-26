#!/bin/bash
set -eo pipefail
echo "Begin - ${0##*/}"
source ./deps/bin/ee

# lint project
printf '\e[1;35m===== Lint dl-guide.sh =====\e[0m\n'
ee bashate -i E006 dl-guide.sh
ee shellcheck -e SC1091 -f gcc dl-guide.sh
# lint CI code
printf '\e[37m===== Lint CI =====\e[0m\n'
ee bashate -i E006 .github/workflows/deps.sh
ee shellcheck -e SC2294 -x -f gcc .github/workflows/deps.sh
ee bashate -i E006 lint.sh
ee shellcheck -x -f gcc lint.sh

echo "Done. - ${0##*/}"
