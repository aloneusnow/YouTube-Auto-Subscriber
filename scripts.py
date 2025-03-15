import time
import random
import pandas as pd
import undetected_chromedriver as uc
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException

# === 🛠️ CONFIGURATION ===
CSV_FILE = ""  # ✅ Update with your CSV file path
LOG_FILE = ""  # ✅ Log file for intended subscriptions
UNINTENDED_LOG_FILE = ""  # ✅ Log file for unintended subscriptions

# ✅ Set up Chrome with an existing profile
options = uc.ChromeOptions()
options.add_argument("--start-maximized")
options.add_argument("--disable-blink-features=AutomationControlled")
options.add_argument("user-data-dir=C:/Users/rajur/AppData/Local/Google/Chrome/User Data")  # ✅ Update as needed
options.add_argument("--profile-directory=Profile")  # ✅ Change if using another profile

# ✅ Start Chrome
driver = uc.Chrome(options=options)
wait = WebDriverWait(driver, 10)  # Slightly reduced wait time
actions = ActionChains(driver)

# === 📜 Function: Subscribe to a Channel & Log Status ===
def subscribe_to_channel(original_channel_name, original_channel_url, known_channels):
    """Visits a YouTube channel, attempts to subscribe, logs result & detects unintended subscriptions."""
    driver.get(original_channel_url)
    time.sleep(random.uniform(3, 6))  # Mimic human delay

    try:
        # ✅ Scroll up/down randomly
        scroll_value = random.randint(200, 600)
        driver.execute_script(f"window.scrollTo(0, {scroll_value});")
        time.sleep(random.uniform(2, 5))

        # ✅ Extract displayed channel name
        try:
            new_channel_name = driver.find_element(By.XPATH, "//yt-formatted-string[@id='text']").text.strip()
        except NoSuchElementException:
            new_channel_name = "Unknown"

        # ✅ Find the subscribe button dynamically
        subscribe_buttons = driver.find_elements(By.XPATH, "//button[@aria-label[contains(., 'Subscribe')]]")

        for button in subscribe_buttons:
            if button.is_displayed():
                actions.move_to_element(button).perform()  # Hover over the button
                time.sleep(random.uniform(1, 3))  # Mimic hesitation
                driver.execute_script("arguments[0].click();", button)  # Use JavaScript click
                print(f"🎉 Subscribed to: {new_channel_name} ({original_channel_url})")
                log_status(original_channel_name, original_channel_url, new_channel_name, "Subscribed")
                time.sleep(random.uniform(2, 5))  # Random delay after clicking
                break  # ✅ Stop after subscribing

        else:
            print(f"⚠️ Already subscribed or button not found: {new_channel_name} ({original_channel_url})")
            log_status(original_channel_name, original_channel_url, new_channel_name, "Already Subscribed")

        # ✅ Check for unintended subscriptions
        detect_unintended_subscriptions(known_channels)

    except (TimeoutException, NoSuchElementException):
        print(f"❌ Subscribe button not found for {original_channel_url}. Maybe already subscribed?")
        log_status(original_channel_name, original_channel_url, "Unknown", "Failed")

    # ✅ Random wait between subscriptions (20-60 sec)
    next_wait = random.randint(20, 60)
    print(f"⏳ Waiting {next_wait} seconds before next subscription...")
    time.sleep(next_wait)

# === 📝 Function: Log Subscription Status ===
def log_status(original_channel_name, original_channel_url, new_channel_name, status):
    """Logs subscription details into the main CSV log file."""
    log_entry = pd.DataFrame([{
        "Original Channel Name": original_channel_name,
        "Original Channel URL": original_channel_url,
        "New Channel Name": new_channel_name,
        "Subscription Status": status
    }])

    # ✅ Append to CSV log file
    log_entry.to_csv(LOG_FILE, mode="a", header=not pd.io.common.file_exists(LOG_FILE), index=False)

# === 🔍 Function: Detect & Log Unintended Subscriptions ===
def detect_unintended_subscriptions(known_channels):
    """Checks for any unintended subscriptions and logs them."""
    driver.get("https://www.youtube.com/feed/channels")
    time.sleep(random.uniform(5, 8))

    try:
        # ✅ Extract list of currently subscribed channels
        channel_elements = driver.find_elements(By.XPATH, "//a[@id='main-link']")
        subscribed_channels = {channel.text.strip(): channel.get_attribute("href") for channel in channel_elements}

        for name, url in subscribed_channels.items():
            if url not in known_channels.values():
                print(f"⚠️ Unintended Subscription Detected: {name} ({url})")
                log_unintended_subscription(name, url)

    except NoSuchElementException:
        print("⚠️ Unable to retrieve subscribed channels list.")

# === 📝 Function: Log Unintended Subscriptions ===
def log_unintended_subscription(channel_name, channel_url):
    """Logs unintended subscriptions into a separate CSV file."""
    log_entry = pd.DataFrame([{
        "Channel Name": channel_name,
        "Channel URL": channel_url,
        "Subscription Type": "Unintended"
    }])

    # ✅ Append to unintended log file
    log_entry.to_csv(UNINTENDED_LOG_FILE, mode="a", header=not pd.io.common.file_exists(UNINTENDED_LOG_FILE), index=False)

# === 🚀 Start Automation ===
# ✅ Load YouTube channel links from CSV
df = pd.read_csv(CSV_FILE)
known_channels = dict(zip(df["Channel Name"], df["Channel Url"]))  # Dictionary of known channels

# ✅ Subscribe to each channel and log results
for index, row in df.iterrows():
    subscribe_to_channel(row["Channel Name"], row["Channel Url"], known_channels)

print("🎉 Subscription process completed! Check the log files for details.")
driver.quit()
