#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Log file path
LOG_FILE="$SCRIPT_DIR/logs/daily_search.log"

# Virtual environment path
VENV_DIR="$SCRIPT_DIR/venv"

# Function to log messages with timestamp
log_message() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$message" >> "$LOG_FILE"
    echo "$message"
}

# Log start of execution
log_message "Starting daily Reddit search..."

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    log_message "Error: Virtual environment not found. Please run setup.sh first"
    exit 1
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Run the Python script with full path
python3 "$SCRIPT_DIR/main.py" 2>&1 | tee -a "$LOG_FILE"

# Store the exit code
exit_code=${PIPESTATUS[0]}

if [ $exit_code -eq 0 ]; then
    log_message "Search completed successfully"
else
    log_message "Error: Search script failed with exit code $exit_code"
fi

# Deactivate virtual environment
deactivate

# Log completion
log_message "Script execution finished" 