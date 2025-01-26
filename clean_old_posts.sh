#!/bin/bash

# Create and execute a temporary Python script
python3 - << 'END_PYTHON'
import json
import os
import time
from datetime import datetime

def clean_json_file(file_path):
    if not os.path.exists(file_path):
        return
    
    # Get current timestamp and calculate cutoff (2 days ago)
    current_time = time.time()
    two_days = 2 * 24 * 60 * 60
    cutoff_time = current_time - two_days
    
    try:
        # Read the current file
        with open(file_path, 'r', encoding='utf-8') as f:
            posts = json.load(f)
        
        # Filter out old posts
        filtered_posts = [
            post for post in posts 
            if post['created_utc'] > cutoff_time
        ]
        
        # Write back the filtered posts
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(filtered_posts, f, indent=2, ensure_ascii=False)
            
        print(f"Cleaned {file_path} - removed posts older than 2 days")
        print(f"Removed {len(posts) - len(filtered_posts)} posts")
        
    except Exception as e:
        print(f"Error processing {file_path}: {str(e)}")

# Get the script directory
script_dir = os.path.dirname(os.path.abspath(__file__))

# Process both files
for filename in ['daily_reddit_results.json', 'weekly_reddit_results.json']:
    file_path = os.path.join(script_dir, filename)
    clean_json_file(file_path)
END_PYTHON