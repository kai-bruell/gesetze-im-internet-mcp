#!/bin/bash

# German Law XML Downloader
# Usage: ./law-xml-downloader.sh <law-name>

set -e

# Parse arguments
FORCE_UPDATE=false
LAW_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --force-update)
            FORCE_UPDATE=true
            shift
            ;;
        *)
            LAW_NAME="$1"
            shift
            ;;
    esac
done

if [ -z "$LAW_NAME" ]; then
    echo "Usage: $0 [--force-update] <law-name>"
    echo "Example: $0 estg"
    echo "Example: $0 --force-update ao_1977"
    exit 1
fi
BASE_URL="https://www.gesetze-im-internet.de"
DOWNLOAD_URL="${BASE_URL}/${LAW_NAME}/xml.zip"
TEMP_DIR=$(mktemp -d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAWS_DIR="${LAWS_DIR:-${SCRIPT_DIR}/laws}"
OUTPUT_DIR="${LAWS_DIR}/${LAW_NAME}"
OUTPUT_FILE="${OUTPUT_DIR}/${LAW_NAME}.xml"

# Check if file already exists
if [ -f "$OUTPUT_FILE" ] && [ "$FORCE_UPDATE" = false ]; then
    echo "File already exists: $OUTPUT_FILE"
    echo "Use --force-update to overwrite"
    exit 0
fi

echo "Downloading ${LAW_NAME}..."

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Download ZIP
if ! curl -L -s -o "${TEMP_DIR}/${LAW_NAME}.zip" "${DOWNLOAD_URL}"; then
    echo "Error: Download failed for '${LAW_NAME}'"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Extract ZIP
cd "${TEMP_DIR}"
unzip -q "${LAW_NAME}.zip"

# Find XML file
XML_FILE=$(find . -name "*.xml" -not -name "*meta*" | head -1)

if [ -z "$XML_FILE" ]; then
    echo "Error: No XML file found"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Copy XML
cp "$XML_FILE" "$OUTPUT_FILE"

# Format XML
xmllint --format --output "$OUTPUT_FILE" "$OUTPUT_FILE"

# Cleanup
rm -rf "${TEMP_DIR}"

echo "Success: $OUTPUT_FILE"