#!/bin/bash
#
# system_info.sh — prints key system information, takes interactive input,
# and saves the running-process list to a file.

CURRENT_DATE=$(date)
CURRENT_HOSTNAME=$(hostname)
CURRENT_USER=$(whoami)
DISK_USAGE=$(df -h /)

echo "===== System Information Script ====="
echo
echo "Date        : $CURRENT_DATE"
echo "Hostname    : $CURRENT_HOSTNAME"
echo "Username    : $CURRENT_USER"
echo
echo "----- Disk Usage (/) -----"
echo "$DISK_USAGE"
echo
echo "----- Running Processes (top 10, COMMAND truncated for display) -----"
ps aux | head -10 | cut -c1-100

echo
read -p "Enter a name for the output directory: " OUTPUT_DIR
mkdir -p "$OUTPUT_DIR"
echo "Created directory: $OUTPUT_DIR"

read -p "Enter a name for the output file (no extension): " OUTPUT_FILE
FILE_PATH="$OUTPUT_DIR/$OUTPUT_FILE.txt"
touch "$FILE_PATH"
echo "Created file: $FILE_PATH"

ps aux > "$FILE_PATH"
echo
echo "Full running-process list saved to: $FILE_PATH"
echo "===== Done ====="
