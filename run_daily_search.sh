#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Log file path
LOG_FILE="$SCRIPT_DIR/daily_search.log"

# Virtual environment path
VENV_DIR="$SCRIPT_DIR/venv"

# Function to log messages with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Create log file if it doesn't exist
touch "$LOG_FILE"

# Log start of execution
log_message "Starting daily Reddit search..."

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    log_message "Error: Virtual environment not found. Please run setup.sh first"
    exit 1
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Run the Python script (no days argument for daily search)
log_message "Starting daily Reddit search..."
if python "$SCRIPT_DIR/main.py"; then
    log_message "Search completed successfully"
else
    log_message "Error: Search script failed with exit code $?"
fi

# Deactivate virtual environment
deactivate

# Log completion
log_message "Script execution finished" 