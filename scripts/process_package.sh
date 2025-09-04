#!/bin/bash

# This script processes a single package for the auto-update workflow.
# It handles storing the old version, updating, extracting, and comparing versions.

set -e

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <PackageName> <Albi0Name> [Albi0UpdateArgs...]"
    exit 1
fi

PACKAGE_NAME=$1
UPDATER_NAME=$2
EXTRACTER_NAME=$3
shift 3 # The rest of the arguments are for albi0 update
ALBIO_UPDATE_ARGS="$@"
MANIFEST_FILE="./package-manifests/${PACKAGE_NAME}.json"

# 1. Store old version if the manifest exists
OLD_VERSION=""
if [ -f "$MANIFEST_FILE" ]; then
  OLD_VERSION=$(jq -r .version "$MANIFEST_FILE")
fi

# 2. Run albi0 update
# The ~/.local/bin path is specific to the GitHub Actions runner environment
~/.local/bin/albi0 update -n "$UPDATER_NAME" -m "$MANIFEST_FILE" $ALBIO_UPDATE_ARGS

# 3. Run albi0 extract
~/.local/bin/albi0 extract -t 2 -n "$EXTRACTER_NAME" "newseer/assetbundles/${PACKAGE_NAME}/*"

# 4. Compare versions and output a line for the commit message if changed
NEW_VERSION=""
if [ -f "$MANIFEST_FILE" ]; then
  NEW_VERSION=$(jq -r .version "$MANIFEST_FILE")
fi

if [ "$NEW_VERSION" != "$OLD_VERSION" ]; then
  echo "- ${PACKAGE_NAME}: ${NEW_VERSION}"
fi
