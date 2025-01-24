#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Log files to delete
LOG_FILES=(
    "$SCRIPT_DIR/logs/setup.log"
    "$SCRIPT_DIR/logs/daily_search.log"
    "$SCRIPT_DIR/logs/weekly_search.log"
    "$SCRIPT_DIR/logs/error.log"
)

# JSON result files to delete
JSON_FILES=(
    "$SCRIPT_DIR/daily_reddit_results.json"
    "$SCRIPT_DIR/weekly_reddit_results.json"
)

echo "Cleaning up log files..."

# Delete log files
for log_file in "${LOG_FILES[@]}"; do
    if [ -f "$log_file" ]; then
        rm "$log_file"
        echo "Deleted: $log_file"
    else
        echo "Not found: $log_file"
    fi
done

# Delete JSON result files
for json_file in "${JSON_FILES[@]}"; do
    if [ -f "$json_file" ]; then
        rm "$json_file"
        echo "Deleted: $json_file"
    else
        echo "Not found: $log_file"
    fi
done

echo "Cleanup completed" 