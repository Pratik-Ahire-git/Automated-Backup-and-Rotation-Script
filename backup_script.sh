#!/bin/bash

# Backup Management Script

# Configuration variables
SRC_DIR="$1"                          # Source directory to back up
BACKUP_DIR="$HOME/backups"            # Backup directory
GOOGLE_DRIVE_FOLDER="MyBackups"       # Google Drive folder name
RETENTION_DAILY=7                     # Number of daily backups to keep
RETENTION_WEEKLY=4                    # Number of weekly backups to keep
RETENTION_MONTHLY=3                   # Number of monthly backups to keep
CURL_URL="$2"                         # URL for cURL request (optional)

# Create a timestamped backup
function create_backup {
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.zip"
    
    # Create a zip archive of the source directory
    zip -r "$BACKUP_FILE" "$SRC_DIR"
    echo "Backup created: $BACKUP_FILE"
    
    # Upload to Google Drive
    rclone copy "$BACKUP_FILE" "gdrive:$GOOGLE_DRIVE_FOLDER"
    echo "Backup uploaded to Google Drive: $GOOGLE_DRIVE_FOLDER"

    # Send cURL request if URL is provided
    if [ ! -z "$CURL_URL" ]; then
        curl -X POST -H "Content-Type: application/json" -d "{\"project\": \"BackupProject\", \"date\": \"$TIMESTAMP\", \"test\": \"BackupSuccessful\"}" "$CURL_URL"
        echo "cURL request sent."
    fi

    # Rotate backups
    rotate_backups
}

# Rotate backups based on retention policy
function rotate_backups {
    cd "$BACKUP_DIR" || exit

    # Delete old daily backups
    ls -t | grep backup | grep -E "_[0-9]{8}_[0-9]{6}" | sed -e "1,${RETENTION_DAILY}d" | xargs rm -f

    # Delete old weekly backups (last Sunday)
    if [ $(date +%u) -eq 7 ]; then
        ls -t | grep backup | grep -E "_[0-9]{8}_[0-9]{6}" | sed -e "1,${RETENTION_WEEKLY}d" | xargs rm -f
    fi

    # Delete old monthly backups (first day of the month)
    if [ $(date +%d) -eq 1 ]; then
        ls -t | grep backup | grep -E "_[0-9]{8}_[0-9]{6}" | sed -e "1,${RETENTION_MONTHLY}d" | xargs rm -f
    fi

    echo "Old backups rotated."
}

# Main execution flow
if [ $# -lt 1 ]; then
    echo "Usage: $0 <source_directory> [<curl_url>]"
    exit 1
fi

# Create backup and upload to Google Drive
create_backup

