#!/bin/bash

# German Law Paragraph Extractor
# Usage: ./get-para.sh <paragraph> <law> [absatz]
# Example: ./get-para.sh "§ 70" estg
# Example: ./get-para.sh "§ 70" estg 2
# Example: ./get-para.sh "§ 70" estg "[1,3,5]"

set -e

# Parse arguments
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo "Usage: $0 <paragraph> <law> [absatz]"
    echo "Example: $0 '§ 70' estg"
    echo "Example: $0 '§ 70' estg 2"
    echo "Example: $0 '§ 70' estg '[1,3,5]'"
    echo "Example: $0 '§ 1' ao_1977"
    exit 1
fi

PARAGRAPH="$1"
LAW_NAME="$2"
ABSATZ="$3"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAWS_DIR="${LAWS_DIR:-${SCRIPT_DIR}/laws}"
XML_FILE="${LAWS_DIR}/${LAW_NAME}/${LAW_NAME}.xml"

# Check if XML file exists
if [ ! -f "$XML_FILE" ]; then
    echo "Error: XML file not found: $XML_FILE"
    echo "Run ./law-xml-downloader.sh $LAW_NAME first"
    exit 1
fi


# Extract paragraph content
CONTENT=$(xmlstarlet sel -t -m "//norm[metadaten/enbez='$PARAGRAPH']" -v "textdaten/text" "$XML_FILE" 2>/dev/null)

if [ -z "$CONTENT" ]; then
    echo "Error: Paragraph '$PARAGRAPH' not found in $LAW_NAME"
    echo
    echo "Available paragraphs:"
    xmlstarlet sel -t -m "//norm/metadaten/enbez" -v "." -n "$XML_FILE" 2>/dev/null | grep "^§" | head -10
    echo "..."
    exit 1
fi

# Filter specific absatz if requested
if [ -n "$ABSATZ" ]; then
    # Check if absatz is a list [1,2,3] or single number
    if [[ "$ABSATZ" =~ ^\[.*\]$ ]]; then
        # Parse list format [1,2,3]
        ABSATZ_LIST=$(echo "$ABSATZ" | sed 's/\[//g' | sed 's/\]//g' | tr ',' ' ')
        echo "=== $PARAGRAPH ($LAW_NAME) - Absätze $ABSATZ ==="
        echo

        for ABS_NUM in $ABSATZ_LIST; do
            # Extract specific absatz
            FILTERED_CONTENT=$(echo "$CONTENT" | sed -n "/^[[:space:]]*($ABS_NUM)/,/^[[:space:]]*([0-9])/p" | sed '$d')

            if [ -n "$FILTERED_CONTENT" ]; then
                echo "--- Absatz $ABS_NUM ---"
                echo "$FILTERED_CONTENT" | sed 's/^ *//' | fold -s -w 80
                echo
            else
                echo "--- Absatz $ABS_NUM (not found) ---"
                echo
            fi
        done
    else
        # Single absatz number
        FILTERED_CONTENT=$(echo "$CONTENT" | sed -n "/^[[:space:]]*($ABSATZ)/,/^[[:space:]]*([0-9])/p" | sed '$d')

        if [ -z "$FILTERED_CONTENT" ]; then
            echo "Error: Absatz '$ABSATZ' not found in $PARAGRAPH"
            echo
            echo "Available Absätze:"
            echo "$CONTENT" | grep -o "^[[:space:]]*([0-9][0-9]*)" | sed 's/[[:space:]]*(\([0-9]*\))/\1/' | sort -n
            exit 1
        fi

        echo "=== $PARAGRAPH ($LAW_NAME) - Absatz $ABSATZ ==="
        echo
        echo "$FILTERED_CONTENT" | sed 's/^ *//' | fold -s -w 80
    fi
else
    echo "=== $PARAGRAPH ($LAW_NAME) ==="
    echo
    # Format and display full content
    echo "$CONTENT" | sed 's/^ *//' | fold -s -w 80
fi
echo