#!/bin/bash

# German Law Table of Contents
# Usage: ./table-of-contents.sh <law>
# Example: ./table-of-contents.sh estg

set -e

# Parse arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 <law>"
    echo "Example: $0 estg"
    echo "Example: $0 ao_1977"
    exit 1
fi

LAW_NAME="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAWS_DIR="${LAWS_DIR:-${SCRIPT_DIR}/laws}"
XML_FILE="${LAWS_DIR}/${LAW_NAME}/${LAW_NAME}.xml"

# Check if XML file exists
if [ ! -f "$XML_FILE" ]; then
    echo "Error: XML file not found: $XML_FILE"
    echo "Run ./law-xml-downloader.sh $LAW_NAME first"
    exit 1
fi

echo "=== Table of Contents: $LAW_NAME ==="
echo

# Extract all paragraph identifiers
xmlstarlet sel -t -m "//norm/metadaten/enbez" -v "." -n "$XML_FILE" 2>/dev/null | grep -v "^$"