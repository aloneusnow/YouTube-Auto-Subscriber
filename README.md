# YouTube Subscriber Bot

An advanced AutoHotkey script for automating YouTube channel subscriptions with human-like behavior and anti-detection measures.

## Features

- 🚀 **Smart Subscription System**: Automatically subscribes to channels from a CSV file
- 🛡️ **Anti-Detection**: Human-like behavior patterns and random delays
- 📊 **Analytics**: Track subscription success rates and performance metrics
- 🖥️ **User Interface**: Easy-to-use GUI for managing subscriptions
- 🔄 **Session Management**: Resume interrupted sessions
- 📝 **Logging**: Detailed logs of all actions

## Requirements

- Windows 7 or later
- AutoHotkey v1.1.33+
- Google Chrome or Firefox
- (Optional) Tesseract OCR for text recognition

## Installation

1. Install [AutoHotkey](https://www.autohotkey.com/)
2. Download or clone this repository
3. Install required dependencies:
   ```
   # Install SQLite3 for database support
   # Install Tesseract OCR (optional) for text recognition
   ```

## Configuration

1. Edit `config.ini` to set your preferences:
   ```ini
   [Browser]
   Type=Chrome
   Headless=false
   Proxy=
   
   [Subscription]
   MinDelay=10
   MaxDelay=30
   
   [Paths]
   ChromePath=C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe
   ```

2. Prepare your `subscriptions.csv` file:
   ```csv
   Channel Name,Channel URL
   Example Channel,https://www.youtube.com/c/example
   ```

## Usage

1. Double-click `youtube_subscriber_enhanced.ahk` to start
2. Use the GUI to:
   - Load your CSV file
   - Start/Stop the subscription process
   - View analytics and logs
   - Configure settings

## Command Line Options

```
youtube_subscriber_enhanced.ahk [options]

Options:
  --csv=FILE      Load channels from specified CSV file
  --headless      Run in headless mode
  --proxy=PROXY   Use specified proxy server
  --help          Show this help message
```

## Troubleshooting

- **Script won't start**: Ensure AutoHotkey is installed and all dependencies are met
- **Browser detection issues**: Check if the browser path in config.ini is correct
- **CAPTCHA detected**: The script will pause and prompt you to solve it

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create a new branch for your feature
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
