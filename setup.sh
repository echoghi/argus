#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Log files
SETUP_LOG="$SCRIPT_DIR/logs/setup.log"
DAILY_LOG="$SCRIPT_DIR/logs/daily_search.log"
WEEKLY_LOG="$SCRIPT_DIR/logs/weekly_search.log"
ERROR_LOG="$SCRIPT_DIR/logs/error.log"

# Requirements file path
REQUIREMENTS_FILE="$SCRIPT_DIR/requirements.txt"

# Virtual environment path
VENV_DIR="$SCRIPT_DIR/venv"

# Create logs directory if it doesn't exist
if [ ! -d "$SCRIPT_DIR/logs" ]; then
    mkdir -p "$SCRIPT_DIR/logs"
    echo "Created logs directory"
fi

# Set directory permissions
chmod 777 "$SCRIPT_DIR/logs"

# Function to log messages with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$SETUP_LOG"
    echo "$1"
}

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ -f /etc/debian_version ]]; then
    OS="debian"
fi

# Create log files and set permissions
for logfile in "$SETUP_LOG" "$DAILY_LOG" "$WEEKLY_LOG" "$ERROR_LOG"; do
    if [ ! -f "$logfile" ]; then
        touch "$logfile"
        echo "Created $logfile"
    fi
    chmod 666 "$logfile"
done

# Set permissions based on OS
if [[ "$OS" == "debian" ]]; then
    ACTUAL_USER=${SUDO_USER:-$USER}
    ACTUAL_GROUP=$(id -gn $ACTUAL_USER)
    chown "$ACTUAL_USER":"$ACTUAL_GROUP" "$SCRIPT_DIR/logs"/*
fi

log_message "Detected OS: $OS"
log_message "Starting setup..."

# Install system dependencies if needed
if [[ "$OS" == "debian" ]]; then
    if ! dpkg -l | grep -q python3-venv; then
        log_message "Installing python3-venv..."
        sudo apt-get update
        sudo apt-get install -y python3-venv
    fi
elif [[ "$OS" == "macos" ]]; then
    if ! command -v python3 &> /dev/null; then
        log_message "Error: Python 3 is not installed. Please install it using Homebrew:"
        log_message "brew install python3"
        exit 1
    fi
fi

# Check if python3 is installed
if ! command -v python3 &> /dev/null; then
    log_message "Error: python3 is not installed"
    if [[ "$OS" == "debian" ]]; then
        log_message "Please install using: sudo apt-get install python3"
    elif [[ "$OS" == "macos" ]]; then
        log_message "Please install using: brew install python3"
    fi
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    log_message "Creating virtual environment..."
    python3 -m venv "$VENV_DIR" || {
        log_message "Error: Failed to create virtual environment"
        exit 1
    }
    
    # Set ownership on Debian
    if [[ "$OS" == "debian" ]]; then
        chown -R "$ACTUAL_USER":"$ACTUAL_GROUP" "$VENV_DIR"
    fi
    
    log_message "Virtual environment created"
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Upgrade pip first
log_message "Upgrading pip..."
python3 -m pip install --upgrade pip

# Install or upgrade required packages in virtual environment
log_message "Installing/upgrading required packages..."
if python3 -m pip install -r "$REQUIREMENTS_FILE"; then
    log_message "Package installation successful"
else
    log_message "Error: Package installation failed"
    deactivate
    exit 1
fi

# Deactivate virtual environment
deactivate

# Create .env from template if it doesn't exist
if [ ! -f .env ]; then
    cp .env.template .env
    echo "Created .env file from template"
fi

# Make scripts executable
chmod +x main.py
chmod +x run_daily_search.sh
chmod +x run_weekly_search.sh

log_message "Setup completed successfully" 