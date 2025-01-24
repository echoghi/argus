# Argus

### Reddit Keyword Monitoring Tool

Argus is a monitoring tool that watches Reddit for specific mentions and sends email notifications with the results. Named after the many-eyed giant of Greek mythology, it vigilantly searches through both posts and comments within a specified timeframe.

## Setup

1. Clone the repository and navigate to the project directory

2. Run the setup script:

```bash
chmod +x setup.sh
./setup.sh
```

This will:

- Create a virtual environment
- Install required packages

3. Edit the .env file with your credentials:

```bash
nano .env  # or use your preferred editor
```

Required credentials:

- Reddit API credentials:
  - `REDDIT_CLIENT_ID`
  - `REDDIT_CLIENT_SECRET`
  - `REDDIT_USER_AGENT`
  - `REDDIT_USERNAME`
- Email configuration:
  - `SMTP_SERVER`
  - `SMTP_PORT`
  - `SENDER_EMAIL`
  - `SENDER_PASSWORD`
  - `RECIPIENT_EMAIL`

4. Configure search parameters in `config.json`:

```json
{
  "subreddit_name": "your_subreddit",
  "search_phrases": ["phrase 1", "phrase 2", "phrase 3"]
}
```

5. Make the bash scripts executable:

   `chmod +x run_daily_search.sh`
   `chmod +x run_weekly_search.sh`
   `chmod +x cleanup.sh`

## Usage

### Running Daily Searches

To search for mentions from today only:

    ./run_daily_search.sh

### Running Weekly Searches

To search for mentions from the past 7 days:

    ./run_weekly_search.sh

### Custom Timeframe

You can also run the Python script directly with a custom number of days:

    python daily_search.py --days 3  # Search past 3 days

## Output

Argus generates two types of output:

1. JSON Files:

   - `daily_reddit_results.json` - Results from daily searches
   - `weekly_reddit_results.json` - Results from weekly searches

2. Email Notifications:
   - Sent to the configured recipient email
   - Contains links to found posts and comments
   - Includes dates for each result

## Logging

Argus maintains log files:

- `daily_search.log` - For daily search operations
- `weekly_search.log` - For weekly search operations

## Automated Running

To run Argus automatically, you can set up cron jobs:

    # Open crontab editor
    crontab -e

    # Add these lines (adjust paths as needed):
    # Run daily search at 9 AM every day
    0 9 * * * /path/to/argus/run_daily_search.sh

    # Run weekly search at 10 AM every Monday
    0 10 * * 1 /path/to/argus/run_weekly_search.sh

## Features

- Filters out locked, removed, or deleted posts
- Checks parent posts of comments to ensure they're still accessible
- Includes timestamps and dates in results
- Configurable search timeframe
- Email notifications with formatted results
- Comprehensive logging
- Environment variable support for sensitive information

## Requirements

- Python 3.6+
- PRAW (Python Reddit API Wrapper)
- python-dotenv
- Access to SMTP server for sending emails
- Reddit API credentials
