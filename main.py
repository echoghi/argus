import praw
import json
from datetime import datetime, timezone, timedelta
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
from dotenv import load_dotenv
import argparse
import traceback
import sys

# Load environment variables
load_dotenv()

# Load configuration
CONFIG_PATH = os.path.join(os.path.dirname(__file__), 'config.json')
with open(CONFIG_PATH, 'r') as f:
    config = json.load(f)

# Define your Reddit API credentials
reddit = praw.Reddit(
    client_id=os.getenv('REDDIT_CLIENT_ID'),
    client_secret=os.getenv('REDDIT_CLIENT_SECRET'),
    user_agent=os.getenv('REDDIT_USER_AGENT'),
    username=os.getenv('REDDIT_USERNAME'),
)

# Get subreddit and search phrases from config
subreddit_name = config['subreddit_name']
search_phrases = config['search_phrases']

# Email configuration
SMTP_SERVER = os.getenv('SMTP_SERVER')
SMTP_PORT = int(os.getenv('SMTP_PORT'))
SENDER_EMAIL = os.getenv('SENDER_EMAIL')
SENDER_PASSWORD = os.getenv('SENDER_PASSWORD')
RECIPIENT_EMAIL = os.getenv('RECIPIENT_EMAIL')

def is_within_timeframe(created_utc, days=0):
    """Check if the timestamp is within specified days (0 = today only)"""
    now = datetime.now(timezone.utc)
    start_date = (now - timedelta(days=days)).date()
    post_date = datetime.fromtimestamp(created_utc, timezone.utc).date()
    return start_date <= post_date <= now.date()

def search_posts(subreddit, phrases, days=0):
    print(f"Searching posts in /r/{subreddit} for the past {days if days > 0 else 'day'}...")
    results = []
    unique_urls = set()  # Track unique URLs
    subreddit_obj = reddit.subreddit(subreddit)

    for phrase in phrases:
        for post in subreddit_obj.search(phrase, limit=100):
            if (is_within_timeframe(post.created_utc, days) and 
                not post.locked and 
                post.removed_by_category is None and 
                post.author is not None):
                
                post_url = f"https://reddit.com{post.permalink}"
                
                if post_url not in unique_urls:
                    unique_urls.add(post_url)
                    results.append({
                        "type": "Post",
                        "title": post.title,
                        "body": post.selftext,
                        "url": post_url,
                        "created_utc": post.created_utc,
                        "date": datetime.fromtimestamp(post.created_utc).strftime('%Y-%m-%d'),
                        "matched_phrase": phrase
                    })

    return results, unique_urls

def search_comments(subreddit, phrases, days=0, unique_urls=None):
    print(f"Searching comments in /r/{subreddit} for the past {days if days > 0 else 'day'}...")
    results = []
    unique_urls = unique_urls or set()  # Use existing set or create new one

    subreddit_obj = reddit.subreddit(subreddit)

    for comment in subreddit_obj.comments(limit=2000):
        if is_within_timeframe(comment.created_utc, days):
            parent_submission = comment.submission
            submission_url = f"https://reddit.com{parent_submission.permalink}"
            
            if (parent_submission.locked or 
                parent_submission.removed_by_category is not None or 
                parent_submission.author is None or
                submission_url in unique_urls):
                continue
                
            for phrase in phrases:
                if phrase.lower() in comment.body.lower():
                    unique_urls.add(submission_url)
                    results.append({
                        "type": "Comment",
                        "title": parent_submission.title,
                        "body": comment.body,
                        "url": submission_url,
                        "created_utc": comment.created_utc,
                        "date": datetime.fromtimestamp(comment.created_utc).strftime('%Y-%m-%d'),
                        "matched_phrase": phrase
                    })
                    break

    return results

def log_error(error_message, error_traceback=None):
    """Write error message and traceback to error log"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    error_path = os.path.join(os.path.dirname(__file__), 'logs', 'error.log')
    
    with open(error_path, 'a') as f:
        f.write(f"[{timestamp}] ERROR: {error_message}\n")
        if error_traceback:
            f.write(f"Traceback:\n{error_traceback}\n")
        f.write("-" * 80 + "\n")

def send_email(results, days=0):
    msg = MIMEMultipart()
    msg['From'] = SENDER_EMAIL
    msg['To'] = RECIPIENT_EMAIL
    current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    timeframe = f"Past {days} Days" if days > 0 else "Today"
    msg['Subject'] = f"Reddit Search Results ({timeframe}) - {current_time}"

    body = f"Relevant mentions on Reddit for {timeframe} as of {current_time}:\n\n"
    for result in results:
        if result['type'] == 'Post':
            body += f"Post: {result['title']}\nMatched: {result['matched_phrase']}\nDate: {result['date']}\nURL: {result['url']}\n\n"
        else:
            body += f"Comment\nMatched: {result['matched_phrase']}\nDate: {result['date']}\nURL: {result['url']}\n\n"

    msg.attach(MIMEText(body, 'plain'))

    try:
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(SENDER_EMAIL, SENDER_PASSWORD)
        server.send_message(msg)
        server.quit()
        print("Email sent successfully!")
    except Exception as e:
        error_msg = f"Failed to send email: {str(e)}"
        log_error(error_msg, traceback.format_exc())
        print(error_msg)

def load_existing_results(filename):
    """Load existing results from JSON file if it exists"""
    try:
        if os.path.exists(filename):
            with open(filename, 'r', encoding='utf-8') as f:
                return {result['url'] for result in json.load(f)}
    except Exception as e:
        print(f"Warning: Could not load existing results: {e}")
    return set()

def main():
    try:
        parser = argparse.ArgumentParser(description='Search Reddit for mentions within a timeframe.')
        parser.add_argument('--days', type=int, default=0, 
                           help='Number of days to search (0 for today only, default: 0)')
        args = parser.parse_args()

        # Determine filename and load existing URLs
        filename = 'weekly_reddit_results.json' if args.days > 0 else 'daily_reddit_results.json'
        existing_urls = load_existing_results(filename)
        
        # Execute search with existing URLs
        post_results, unique_urls = search_posts(subreddit_name, search_phrases, args.days)
        unique_urls.update(existing_urls)  # Add existing URLs to the set
        comment_results = search_comments(subreddit_name, search_phrases, args.days, unique_urls)

        # Filter out results that exist in the previous results
        new_results = [result for result in (post_results + comment_results) 
                      if result['url'] not in existing_urls]

        # Save to JSON file
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(new_results, f, indent=2, ensure_ascii=False)

        print(f"Saved {len(new_results)} new results to {filename}")

        # Send email if new results were found
        if new_results:
            send_email(new_results, args.days)

    except Exception as e:
        error_msg = f"Script execution failed: {str(e)}"
        log_error(error_msg, traceback.format_exc())
        print(error_msg)
        sys.exit(1)

if __name__ == "__main__":
    main() 