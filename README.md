# YouTube-Auto-Subscriber
🚀 Automated YouTube Subscription Bot 💡 Uses Selenium &amp; undetected-chromedriver | 🎯 Mimics Human-Like Interaction | 🔄 Logs Subscription Status Locally

🔹 About This Project  
This Python script automates YouTube channel subscriptions using Selenium WebDriver and undetected-chromedriver. It loads a list of channels from a CSV file, navigates to each channel, and attempts to subscribe while emulating human-like behavior.

✅ Works with Chrome user profiles (No need to log in every time)  
✅ Handles login automatically if required  
✅ Simulates real user actions with random delays  
✅ Detects already subscribed channels and skips them  
✅ Logs all subscription activities in a CSV file  

🔹 Features  
✔️ Automated YouTube Login – Logs in automatically if required  
✔️ Chrome Profile Support – Uses existing YouTube sessions  
✔️ Human-Like Interaction – Adds random delays & scrolling behavior  
✔️ Subscription Status Detection – Skips already subscribed channels  
✔️ Error Handling & Recovery – Handles page timeouts & missing elements  
✔️ Local CSV Log – Stores subscription status, channel names, and links  
✔️ Randomized Timing – Varies time taken per subscription to avoid detection  

🔹 How It Works  
1️⃣ Loads a CSV file with YouTube channel links  
2️⃣ Opens Chrome with user data (No need to log in every time)  
3️⃣ Navigates to each channel URL  
4️⃣ Searches for the Subscribe button and clicks it (if not already subscribed)  
5️⃣ Adds randomized delays (between 10s - 45s per channel)  
6️⃣ Logs the subscription status (Subscribed ✅ / Already Subscribed ⚠️)  

🔹 Setup Instructions  
🔧 Prerequisites  
Python 3.x installed  
Google Chrome installed  
ChromeDriver (matching version)  

Install dependencies:  
pip install selenium undetected-chromedriver pandas  

🚀 Running the Script  
1️⃣ Clone this repository  

2️⃣ Update the config section with your Chrome profile path & CSV file location  
3️⃣ Run the script  
python   

🔹 CSV Log Format  
The script generates a log file with the following details:  

Old Channel Name	  Current Channel Name    	Channel URL	        Subscription Status
Example Channel	    Example Channel	          youtube.com/xyz 	   Subscribed ✅
Another Channel 	  Another Channel	          youtube.com/abc	    Already Subscribed ⚠️

🔹 Roadmap & Future Improvements  
🚀 Improve YouTube Element Detection for Different Languages  
⚡ Optimize Timing for Faster Execution While Remaining Human-Like  
📊 Enhance Logging with More Detailed Analytics  
🛠️ Add Multi-Threading for Parallel Subscription Processing  

🔹 Disclaimer  
⚠️ This tool is for educational purposes only. Use responsibly. Automating interactions with YouTube may violate its Terms of Service, so proceed at your own risk.  

