# YouTube Subscriber Bot - User Guide

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Installation](#installation)
3. [Quick Start](#quick-start)
4. [Configuration](#configuration)
5. [Usage](#usage)
6. [Troubleshooting](#troubleshooting)
7. [FAQ](#frequently-asked-questions)
8. [Support](#support)

## System Requirements

- **Operating System**: Windows 7/8/10/11 (64-bit recommended)
- **Memory**: 4GB RAM minimum, 8GB recommended
- **Storage**: 100MB free disk space
- **Browsers**: Google Chrome v90+ or Firefox v100+
- **Other**: .NET Framework 4.8 or later

## Installation

### Method 1: Using the Installer (Recommended)

1. Download the latest release from our [GitHub repository](https://github.com/yourusername/youtube-subscriber-bot)
2. Run the installer `YouTubeSubscriberBot_Setup.exe`
3. Follow the on-screen instructions
4. The installer will create shortcuts on your desktop and Start Menu

### Method 2: Manual Setup

1. **Install AutoHotkey**
   - Download from [https://www.autohotkey.com/](https://www.autohotkey.com/)
   - Run the installer and select "Express Installation"
   - Restart your computer if prompted

2. **Download Required Files**
   - Create a new folder for the bot (e.g., `C:\YouTubeBot\`)
   - Copy these files into the folder:
     - `youtube_subscriber_enhanced.ahk`
     - `config.ini`
     - `subscriptions.csv` (create if it doesn't exist)
     - `README.md`
     - `LICENSE`

3. **Install Dependencies**
   - The bot will automatically download required libraries on first run
   - Ensure you have a stable internet connection

## Quick Start

### 1. Prepare Your Channel List

1. Create a file named `subscriptions.csv` in the bot's folder
2. Add channels in this format:
   ```csv
   Channel Name,Channel URL
   Example Channel,https://www.youtube.com/c/example
   Tech Reviews,https://www.youtube.com/c/techreviews
   ```

### 2. Configure the Bot

Edit `config.ini` to set your preferences:

```ini
[Browser]
Type=Chrome
Headless=false

[Subscription]
MinDelay=15
MaxDelay=45
MaxSubscriptions=20

[Logging]
EnableLogging=true
LogLevel=2  ; 1=Error, 2=Info, 3=Debug
```

### 3. Run the Bot

#### Windows GUI
1. Double-click `youtube_subscriber_enhanced.ahk`
2. The bot will appear in your system tray
3. Right-click the icon and select "Start"

#### Command Line
```bash
# Basic usage
youtube_subscriber_enhanced.ahk

# With options
youtube_subscriber_enhanced.ahk --headless --csv=my_channels.csv --log=3
```

## Configuration

### config.ini Settings

| Section | Key | Values | Default | Description |
|---------|-----|--------|---------|-------------|
| Browser | Type | Chrome/Firefox/Edge | Chrome | Browser to use |
| | Headless | true/false | false | Run browser in background |
| | Proxy | host:port | | Proxy server (optional) |
| Subscription | MinDelay | 5-60 | 10 | Minimum delay between actions (seconds) |
| | MaxDelay | 10-120 | 30 | Maximum delay between actions |
| | MaxSubscriptions | 0-1000 | 0 | Maximum subscriptions per session (0=unlimited) |
| Logging | EnableLogging | true/false | true | Enable logging |
| | LogLevel | 1-3 | 2 | 1=Error, 2=Info, 3=Debug |

## Usage

### System Tray Controls
- **Right-click** the icon for menu options
- **Left-click** to show/hide the main window

### Hotkeys
| Shortcut | Action |
|----------|--------|
| Ctrl+Alt+S | Start the bot |
| Ctrl+Alt+P | Pause the bot |
| Ctrl+Alt+R | Resume the bot |
| Ctrl+Alt+X | Exit the bot |

### GUI Features
1. **Dashboard**
   - Real-time statistics
   - Recent activity log
   - System status

2. **Subscriptions**
   - View/Add/Remove channels
   - Start/Pause subscription process
   - View subscription status

3. **Analytics**
   - Performance metrics
   - Success/Failure rates
   - Time-based statistics

4. **Settings**
   - Configure bot behavior
   - Set up proxies
   - Adjust delays and timeouts

## Troubleshooting

### Common Issues

#### Bot won't start
- Ensure AutoHotkey is installed
- Check if another instance is already running
- Run as Administrator if you see permission errors

#### Browser not detected
- Verify browser path in `config.ini`
- Make sure Chrome/Firefox is installed
- Update to the latest browser version

#### CAPTCHA Detection
- The bot will pause and notify you
- Solve the CAPTCHA manually
- Click "Resume" to continue

### Log Files
Check these files for error details:
- `error_log.txt` - Critical errors
- `debug.log` - Detailed execution log (if debug mode is enabled)
- `subscription_log.csv` - Subscription history

## Frequently Asked Questions

### Is this bot safe to use?
- The bot simulates human behavior but use it responsibly
- Avoid aggressive settings to prevent temporary blocks
- We're not responsible for any account restrictions

### How many subscriptions can I do per day?
- YouTube has limits to prevent abuse
- We recommend 20-30 subscriptions per day
- Use the `MaxSubscriptions` setting to control this

### Can I run multiple instances?
- Yes, but each instance should use a different account
- Be aware of system resource usage

---
*Last Updated: May 2024*
