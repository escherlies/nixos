#!/usr/bin/env bash

# Fixes Signal time format not working
# https://github.com/signalapp/Signal-Desktop/issues/4252
# Replaces "localeOverride": null
# with     "localeOverride": "en-DE"
# in       ~/.config/Signal/ephemeral.json


# Exit on error
set -e

# Script to update Signal's locale setting
# Changes "localeOverride": null to "localeOverride": "en-DE" in ~/.config/Signal/ephemeral.json

SIGNAL_CONFIG="$HOME/.config/Signal/ephemeral.json"

# Check if the config file exists
if [ ! -f "$SIGNAL_CONFIG" ]; then
    echo "Error: Signal config file not found at $SIGNAL_CONFIG"
    exit 1
fi

# Create a backup of the original file
BACKUP_FILE="${SIGNAL_CONFIG}.bak"
cp "$SIGNAL_CONFIG" "$BACKUP_FILE"
echo "Created backup at $BACKUP_FILE"

# Replace "localeOverride": null with "localeOverride": "en-DE"
sed -i 's/"localeOverride": null/"localeOverride": "en-DE"/g' "$SIGNAL_CONFIG"

# Check if the replacement was successful
if grep -q '"localeOverride": "en-DE"' "$SIGNAL_CONFIG"; then
    echo "Successfully updated Signal locale to en-DE"
    echo "Original configuration backed up at $BACKUP_FILE"
else
    echo "Warning: Replacement may not have been successful"
    echo "Please check $SIGNAL_CONFIG manually"
fi

echo "Done!"
