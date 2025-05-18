; ===================================================================
; YouTube Subscriber Bot - Enhanced Version
; ===================================================================
; Description: An advanced AutoHotkey script for automating YouTube channel
;              subscriptions with human-like behavior and anti-detection measures.
; Version:     1.0.0
; Author:      Your Name
; License:     MIT
; ===================================================================

#SingleInstance Force
#NoEnv
#Warn All, Off
#Include <JSON>
#Include <Gdip_All>
#Include <Class_SQLiteDB>
#Include <Array>
#Include <JSON>
#Include <Gdip_All>
#Include <Class_SQLiteDB>
SetWorkingDir %A_ScriptDir%
SendMode Input
SetBatchLines -1

; === GDI+ Initialization ===
If !pToken := Gdip_Startup()
{
    MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
    ExitApp
}
OnExit, ExitSub

; === ERROR HANDLING FUNCTIONS ===
TakeScreenshot(prefix := "error") {
    static counter := 0
    counter++
    
    FormatTime, timestamp,, yyyyMMdd_HHmmss
    screenshotPath := A_ScriptDir "\screenshots\" prefix "_" timestamp "_" counter ".png"
    
    ; Create screenshots directory if it doesn't exist
    if !FileExist(A_ScriptDir "\screenshots")
        FileCreateDir, %A_ScriptDir%\screenshots
    
    ; Take screenshot using GDI+
    pBitmap := Gdip_BitmapFromScreen("0|0|" A_ScreenWidth "|" A_ScreenHeight)
    Gdip_SaveBitmapToFile(pBitmap, screenshotPath)
    Gdip_DisposeImage(pBitmap)
    
    return screenshotPath
}

LogError(channelTitle, channelUrl, errorCode, errorMessage) {
    screenshotPath := TakeScreenshot("error")
    
    ; Log to database
    DB.Exec("""
        INSERT INTO subscriptions (channel_title, channel_url, status, error_code, screenshot_path)
        VALUES ('" . DB.Escape(channelTitle) . "', '" . DB.Escape(channelUrl) . "', '" . DB.Escape("Error: " errorMessage) . "', " . errorCode . ", '" . DB.Escape(screenshotPath) . "')
    """)
    
    ; Also log to file
    FormatTime, timestamp,, yyyy-MM-dd HH:mm:ss
    FileAppend, [%timestamp%] ERROR - %channelTitle% - %errorMessage% (Code: %errorCode%)`n, %A_ScriptDir%\error_log.txt
    
    ; Show notification
    TrayTip, YouTube Bot Error, % "Error: " errorMessage, 3, 3
}

CheckForCaptcha() {
    ; Check for common CAPTCHA elements
    if WinExist("CAPTCHA") || WinExist("Verify") || WinExist("Robot") {
        screenshotPath := TakeScreenshot("captcha")
        MsgBox, 16, CAPTCHA Detected, Please solve the CAPTCHA and click OK to continue.
        return true
    }
    return false
}

RecoverFromError() {
    ; Try to recover from common errors
    if CheckForCaptcha()
        return
        
    ; Try refreshing the page
    Send, {F5}
    Sleep, 5000
    
    ; Try going back to YouTube home
    Send, ^l
    Send, https://www.youtube.com/{Enter}
    Sleep, 5000
    
    ; If still having issues, try logging out and back in
    LogoutYouTube()
    Sleep, 2000
    LoginToYouTube()
}

; === ANALYTICS FUNCTIONS ===
StartTimer() {
    return A_TickCount
}

LogAnalytics(action, status, details := "", executionTime := "") {
    static lastActionTime := 0
    
    ; Calculate execution time if not provided
    if (executionTime = "") {
        executionTime := A_TickCount - lastActionTime
    }
    lastActionTime := A_TickCount
    
    ; Log to database
    DB.Exec("""
        INSERT INTO analytics (action, status, details, execution_time)
        VALUES ('" . DB.Escape(action) . "', '" . DB.Escape(status) . "', '" . DB.Escape(details) . "', " . executionTime . ")
    """)
    
    ; Also log to file
    FormatTime, timestamp,, yyyy-MM-dd HH:mm:ss
    FileAppend, [%timestamp%] %action% - %status% - %details% (Took: %executionTime%ms)`n, %A_ScriptDir%\analytics.log
}

GenerateReport() {
    ; Generate daily report
    FormatTime, today,, yyyy-MM-dd
    
    ; Get stats from database
    stats := {}
    
    ; Total actions
    DB.GetTable("""
        SELECT action, status, COUNT(*) as count 
        FROM analytics 
        WHERE date(timestamp) = date('now') 
        GROUP BY action, status
    """, Result)
    
    ; Calculate success rate
    DB.GetTable("""
        SELECT 
            COUNT(CASE WHEN status = 'Success' THEN 1 END) as success,
            COUNT(*) as total
        FROM analytics
        WHERE date(timestamp) = date('now')
    """, SuccessRate)
    
    ; Get average execution time
    DB.GetTable("""
        SELECT action, AVG(execution_time) as avg_time
        FROM analytics 
        WHERE date(timestamp) = date('now')
        GROUP BY action
    """, AvgTimes)
    
    ; Generate report
    report = 
    (
=== YouTube Bot Daily Report ===
Date: %today%

--- Summary ---
Total Actions: %Result.RowCount%
Success Rate: % Format("{:.1f}%", (SuccessRate.Rows[1,1] / SuccessRate.Rows[1,2]) * 100)

--- Actions Breakdown ---
    )
    
    ; Add action details
    for each, row in Result.Rows {
        report .= row[1] " - " row[2] ": " row[3] "`n"
    }
    
    report .= "`n--- Performance ---`n"
    
    ; Add performance details
    for each, row in AvgTimes.Rows {
        report .= row[1] ": " Format("{:.1f}", row[2]) " ms`n"
    }
    
    ; Save report to file
    FileDelete, %A_ScriptDir%\reports\%today%_report.txt
    FileAppend, %report%, %A_ScriptDir%\reports\%today%_report.txt
    
    return report
}

; === SQLite Database Setup ===
DB := new SQLiteDB
if !DB.OpenDB(A_ScriptDir . "\youtube_bot.db") {
    MsgBox, 16, SQLite Error, % "Can't open/create database!`n`n" DB.ErrorMsg " - " DB.ErrorCode
    ExitApp
}

; Create tables if they don't exist
DB.Exec("""
    CREATE TABLE IF NOT EXISTS subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        channel_title TEXT NOT NULL,
        channel_url TEXT NOT NULL,
        status TEXT NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        error_code INTEGER DEFAULT 0,
        screenshot_path TEXT
    );
    
    CREATE TABLE IF NOT EXISTS analytics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        status TEXT NOT NULL,
        details TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        execution_time INTEGER
    );
""")

; === GUI FUNCTIONS ===
CreateGUI() {
    global
    
    ; Create main window
    Gui, Main:New, +Resize +MinSize800x600, YouTube Subscriber Bot
    
    ; Menu bar
    Menu, FileMenu, Add, &Load CSV, GuiLoadCSV
    Menu, FileMenu, Add, &Save Settings, GuiSaveSettings
    Menu, FileMenu, Add, E&xit, GuiClose
    Menu, HelpMenu, Add, &Help, GuiShowHelp
    Menu, HelpMenu, Add, &About, GuiShowAbout
    Menu, MenuBar, Add, &File, :FileMenu
    Menu, MenuBar, Add, &Help, :HelpMenu
    Gui, Menu, MenuBar
    
    ; Status bar
    Gui, Add, StatusBar,, Ready
    
    ; Main tabs
    Gui, Add, Tab3, x10 y10 w780 h540 vMainTabs, Dashboard | Subscriptions | Analytics | Settings
    
    ; Dashboard Tab
    Gui, Tab, 1
    Gui, Add, GroupBox, x20 y40 w760 h150, Statistics
    Gui, Add, Text, x30 y70, Subscriptions Today:
    Gui, Add, Text, vSubsToday x120 y70 w100, 0
    Gui, Add, Text, x30 y100, Success Rate:
    Gui, Add, Text, vSuccessRate x120 y100 w100, 0`%
    Gui, Add, Text, x30 y130, Current Status:
    Gui, Add, Text, vCurrentStatus x120 y130 w400, Idle
    
    Gui, Add, GroupBox, x20 y200 w760 h200, Recent Activity
    Gui, Add, ListView, x30 y220 w740 h170 vActivityList, Time|Action|Status|Details
    LV_ModifyCol(1, 100)
    LV_ModifyCol(2, 150)
    LV_ModifyCol(3, 100)
    LV_ModifyCol(4, 300)
    
    ; Subscriptions Tab
    Gui, Tab, 2
    Gui, Add, Button, x20 y40 w120 h30 vAddBtn gAddSubscription, &Add Subscription
    Gui, Add, Button, x150 y40 w120 h30 vRemoveBtn gRemoveSubscription, &Remove
    Gui, Add, Button, x280 y40 w120 h30 vStartBtn gStartSubscription, &Start
    Gui, Add, Button, x410 y40 w120 h30 vPauseBtn gPauseSubscription, &Pause
    Gui, Add, ListView, x20 y80 w760 h450 vSubsList, #|Channel|URL|Status|Last Updated
    LV_ModifyCol(1, 30)
    LV_ModifyCol(2, 200)
    LV_ModifyCol(3, 300)
    LV_ModifyCol(4, 100)
    LV_ModifyCol(5, 150)
    
    ; Analytics Tab
    Gui, Tab, 3
    Gui, Add, DateTime, x20 y40 vReportDate, yyyy-MM-dd
    Gui, Add, Button, x180 y40 w120 h30 gGenerateReport, &Generate Report
    Gui, Add, Button, x310 y40 w120 h30 gExportReport, &Export to CSV
    Gui, Add, Edit, x20 y80 w760 h450 vReportText ReadOnly Multi
    
    ; Settings Tab
    Gui, Tab, 4
    Gui, Add, GroupBox, x20 y40 w760 h200, Browser Settings
    Gui, Add, Text, x30 y70, Browser:
    Gui, Add, DropDownList, x100 y65 w200 vSettingBrowser, Chrome||Firefox|Edge
    Gui, Add, Text, x30 y110, Headless Mode:
    Gui, Add, CheckBox, x100 y110 vSettingHeadless
    Gui, Add, Text, x30 y150, Proxy Server:
    Gui, Add, Edit, x100 y145 w200 vSettingProxy
    
    Gui, Add, GroupBox, x20 y250 w760 h150, Subscription Settings
    Gui, Add, Text, x30 y280, Min Delay (seconds):
    Gui, Add, Edit, x140 y275 w100 vSettingMinDelay, 10
    Gui, Add, Text, x30 y310, Max Delay (seconds):
    Gui, Add, Edit, x140 y305 w100 vSettingMaxDelay, 30
    Gui, Add, Button, x30 y340 w120 h30 gSaveSettings, &Save Settings
    
    ; Show the window
    Gui, Show, w800 h600
    
    ; Load settings
    GuiLoadSettings()
}

UpdateStatus(message) {
    GuiControl,, CurrentStatus, %message%
    SB_SetText("Status: " . message)
    LogAnalytics("Status Update", "Info", message)
}

AddActivity(time, action, status, details := "") {
    Gui, ListView, ActivityList
    LV_Insert(1, "", time, action, status, details)
    
    ; Keep only the last 100 entries
    while (LV_GetCount() > 100) {
        LV_Delete()
    }
}

UpdateStats() {
    ; Update dashboard statistics
    DB.GetTable("""
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN status = 'Subscribed' THEN 1 ELSE 0 END) as success
        FROM subscriptions 
        WHERE date(timestamp) = date('now')
    """, Stats)
    
    GuiControl,, SubsToday, % Stats.Rows[1,1]
    if (Stats.Rows[1,1] > 0) {
        successRate := Round((Stats.Rows[1,2] / Stats.Rows[1,1]) * 100, 1)
        GuiControl,, SuccessRate, %successRate%`%
    }
}

; === EVENT HANDLERS ===
GuiLoadCSV() {
    FileSelectFile, csvFile, 3, , Open CSV File, CSV Files (*.csv)
    if (csvFile != "") {
        ; Load and process CSV file
        GuiControl,, CurrentStatus, Loading CSV file...
        ; Add your CSV loading logic here
        UpdateStatus("CSV file loaded: " . csvFile)
    }
}

GuiSaveSettings() {
    ; Save settings to INI file
    Gui, Submit, NoHide
    
    IniWrite, %SettingBrowser%, settings.ini, Browser, Type
    IniWrite, %SettingHeadless%, settings.ini, Browser, Headless
    IniWrite, %SettingProxy%, settings.ini, Browser, Proxy
    IniWrite, %SettingMinDelay%, settings.ini, Subscription, MinDelay
    IniWrite, %SettingMaxDelay%, settings.ini, Subscription, MaxDelay
    
    UpdateStatus("Settings saved successfully")
}

GuiLoadSettings() {
    ; Load settings from INI file
    IniRead, browser, settings.ini, Browser, Type, Chrome
    IniRead, headless, settings.ini, Browser, Headless, 0
    IniRead, proxy, settings.ini, Browser, Proxy, 
    IniRead, minDelay, settings.ini, Subscription, MinDelay, 10
    IniRead, maxDelay, settings.ini, Subscription, MaxDelay, 30
    
    GuiControl,, SettingBrowser, |%browser%
    GuiControl,, SettingHeadless, %headless%
    GuiControl,, SettingProxy, %proxy%
    GuiControl,, SettingMinDelay, %minDelay%
    GuiControl,, SettingMaxDelay, %maxDelay%
}

GuiShowHelp() {
    MsgBox, 64, Help,
    (
    YouTube Subscriber Bot Help
    
    [Dashboard]
    - View statistics and recent activity
    
    [Subscriptions]
    - Add/remove channels to subscribe to
    - Start/pause the subscription process
    
    [Analytics]
    - View performance reports
    - Export data to CSV
    
    [Settings]
    - Configure browser and subscription settings
    )
}

GuiShowAbout() {
    MsgBox, 64, About, YouTube Subscriber Bot v1.0`n`nA tool for automatically subscribing to YouTube channels.

    )
}

; === SMART THROTTLING SYSTEM ===
; This system dynamically adjusts delays and behavior to avoid detection

; Global variables for throttling
global LastActionTime := 0
global ActionDelays := {}
global HumanPatterns := {}

; Initialize human-like patterns
InitHumanPatterns() {
    ; Common human-like delays between actions (in milliseconds)
    HumanPatterns["page_load"] := {min: 2000, max: 5000, mean: 3500, stddev: 800}
    HumanPatterns["button_click"] := {min: 300, max: 1200, mean: 700, stddev: 200}
    HumanPatterns["typing"] := {min: 50, max: 200, mean: 100, stddev: 30}
    HumanPatterns["navigation"] := {min: 500, max: 2000, mean: 1000, stddev: 300}
    
    ; Initialize action delays with default values
    for action, _ in HumanPatterns {
        ActionDelays[action] := HumanPatterns[action].mean
    }
}

; Get a human-like delay for a specific action
GetHumanDelay(actionType) {
    if (!HumanPatterns.HasKey(actionType)) {
        return Random(300, 1000)  ; Default delay if action type not found
    }
    
    ; Get pattern for this action
    pattern := HumanPatterns[actionType]
    
    ; Add some randomness to the delay
    delay := RandomGaussian(pattern.mean, pattern.stddev)
    
    ; Ensure delay is within min/max bounds
    delay := Max(delay, pattern.min)
    delay := Min(delay, pattern.max)
    
    ; Add some variation based on recent behavior
    if (ActionDelays[actionType] > 0) {
        ; Slight adjustment based on previous delay (tend to alternate between faster/slower)
        delay := (delay + (pattern.mean * 1.5) - (ActionDelays[actionType] * 0.5)) / 2
    }
    
    ; Store this delay for next time
    ActionDelays[actionType] := delay
    
    return Round(delay)
}

; Generate random number with normal distribution
RandomGaussian(mean, stddev) {
    ; Box-Muller transform
    static z1 := 0
    static generate := 0
    
    generate := !generate
    if (!generate) {
        return z1 * stddev + mean
    }
    
    u1 := 0, u2 := 0
    while (u1 <= 0) {
        Random, u1
    }
    Random, u2
    
    z0 := Sqrt(-2 * Ln(u1)) * Cos(2 * 3.141592653589793 * u2)
    z1 := Sqrt(-2 * Ln(u1)) * Sin(2 * 3.141592653589793 * u2)
    
    return z0 * stddev + mean
}

; Human-like mouse movement
HumanMouseMove(x, y, speed := "") {
    ; Get current mouse position
    CoordMode, Mouse, Screen
    MouseGetPos, x0, y0
    
    ; Calculate distance
    dx := x - x0
    dy := y - y0
    distance := Sqrt(dx*dx + dy*dy)
    
    ; Determine number of steps (more steps for longer distances)
    steps := Max(5, Min(50, distance / 5))
    
    ; Generate a curved path (Bezier curve)
    points := []
    Random, ctrl1x, -50, 50
    Random, ctrl1y, -50, 50
    Random, ctrl2x, -50, 50
    Random, ctrl2y, -50, 50
    
    Loop, % steps + 1 {
        t := (A_Index - 1) / steps
        ; Cubic Bezier curve
        mt := 1 - t
        xpos := x0*mt*mt*mt + (x0+ctrl1x)*3*mt*mt*t + (x+ctrl2x)*3*mt*t*t + x*t*t*t
        ypos := y0*mt*mt*mt + (y0+ctrl1y)*3*mt*mt*t + (y+ctrl2y)*3*mt*t*t + y*t*t*t
        
        points.Push({x: xpos, y: ypos})
    }
    
    ; Move mouse along the path
    for i, point in points {
        MouseMove, % point.x, % point.y, 0
        Sleep, 5  ; Small delay for smooth movement
    }
    
    ; Add some human-like imprecision
    Random, offsetX, -3, 3
    Random, offsetY, -3, 3
    MouseMove, x+offsetX, y+offsetY, 0
    
    ; Random delay after movement
    Random, delay, 30, 150
    Sleep, delay
}

; Human-like typing
HumanType(text) {
    global
    
    ; Randomly decide typing speed (characters per minute)
    static lastSpeed := 0
    if (lastSpeed = 0) {
        Random, lastSpeed, 200, 400  ; 200-400 CPM is average typing speed
    } else {
        ; Slight variation from last speed
        Random, variation, -20, 20
        lastSpeed := Max(100, Min(600, lastSpeed + variation))
    }
    
    ; Calculate delay between keystrokes
    cpm := lastSpeed
    msPerChar := 60000 / cpm  ; Convert CPM to ms/char
    
    ; Type each character with slight randomness
    Loop, Parse, text
    {
        ; Random delay between keystrokes
        Random, delay, msPerChar * 0.7, msPerChar * 1.3
        Random, skip, 1, 100
        
        ; Occasionally skip or repeat a key (typing mistakes)
        if (skip < 2) {  ; 1% chance to skip a key
            continue
        } else if (skip > 99) {  // 1% chance to repeat a key
            Send, % A_LoopField
            Random, repeatDelay, 50, 200
            Sleep, repeatDelay
        }
        
        Send, % A_LoopField
        Sleep, delay
    }
    
    ; Random delay after typing
    Random, delay, 100, 500
    Sleep, delay
}

; Initialize the throttling system
InitHumanPatterns()

; ===================================================================
; CONFIGURATION
; ===================================================================
; This section contains all the configurable parameters for the script.
; For most users, the default values should work fine.
; ===================================================================

; Load configuration from INI file if it exists
if (FileExist("config.ini")) {
    IniRead, BrowserType, config.ini, Browser, Type, Chrome
    IniRead, HeadlessMode, config.ini, Browser, Headless, 0
    IniRead, ProxyServer, config.ini, Browser, Proxy
    IniRead, MinDelay, config.ini, Subscription, MinDelay, 10
    IniRead, MaxDelay, config.ini, Subscription, MaxDelay, 30
    IniRead, MaxSubscriptions, config.ini, Subscription, MaxSubscriptions, 0
    IniRead, EnableLogging, config.ini, Logging, EnableLogging, 1
    IniRead, DebugMode, config.ini, Advanced, Debug, 0
} else {
    ; Default values if config.ini doesn't exist
    BrowserType := "Chrome"
    HeadlessMode := 0
    ProxyServer := ""
    MinDelay := 10
    MaxDelay := 30
    MaxSubscriptions := 0
    EnableLogging := 1
    DebugMode := 0
}

; === SCRIPT CONSTANTS ===
#NoTrayIcon  ; Disable tray icon by default
SetBatchLines, -1  ; Run script at maximum speed
SetWorkingDir, %A_ScriptDir%  ; Use script's directory as working directory

; === GLOBAL VARIABLES ===
global VERSION := "1.0.0"
global IS_RUNNING := false
global IS_PAUSED := false
global TOTAL_SUBSCRIBED := 0
global TOTAL_FAILED := 0
global START_TIME := A_Now

global CSV_FILE := "subscriptions.csv"  ; Input CSV file with channel URLs
global LOG_FILE := "subscription_log.csv"  ; Output log file
global ERROR_LOG := "error_log.txt"  ; Error log file
global DEBUG_LOG := "debug.log"  ; Debug log file

; === BROWSER SETTINGS ===
BROWSER_TYPE := BrowserType  ; Chrome, Firefox, Edge
BROWSER_HEADLESS := HeadlessMode  ; Run browser in headless mode
BROWSER_PROXY := ProxyServer  ; Proxy server (format: host:port)

; === SUBSCRIPTION SETTINGS ===
MIN_DELAY := MinDelay * 1000  ; Convert to milliseconds
MAX_DELAY := MaxDelay * 1000  ; Convert to milliseconds
MAX_RETRIES := 3  ; Maximum number of retries for failed subscriptions
MAX_SUBSCRIPTIONS := MaxSubscriptions  ; Maximum number of subscriptions per session (0 = unlimited)

; === LOGGING SETTINGS ===
LOG_LEVEL := DebugMode ? 3 : 1  ; 1=Error, 2=Info, 3=Debug
LOG_TO_FILE := EnableLogging  ; Enable/disable file logging

; === PATHS ===
CHROME_PATH := "C:\Program Files\Google\Chrome\Application\chrome.exe"
FIREFOX_PATH := "C:\Program Files\Mozilla Firefox\firefox.exe"
EDGE_PATH := "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

; ===================================================================
; END OF CONFIGURATION
; ===================================================================

; Show help if requested
if (A_Args[1] = "--help" or A_Args[1] = "/?" or A_Args[1] = "-h") {
    ShowHelp()
    ExitApp
}

; ===================================================================
; HELP FUNCTION
; ===================================================================
ShowHelp() {
    MsgBox, 64, YouTube Subscriber Bot Help,
    (
    YouTube Subscriber Bot v%VERSION%
    
    USAGE:
      youtube_subscriber_enhanced.ahk [OPTIONS]
    
    OPTIONS:
      --help, -h, /?    Show this help message
      --config=FILE     Load configuration from FILE
      --csv=FILE        Load channels from CSV file
      --headless        Run browser in headless mode
      --proxy=HOST:PORT Use specified proxy server
      --debug           Enable debug mode
      --log=LEVEL       Set log level (1=Error, 2=Info, 3=Debug)
    
    EXAMPLES:
      Run with custom CSV: youtube_subscriber_enhanced.ahk --csv=my_channels.csv
      Run in headless mode: youtube_subscriber_enhanced.ahk --headless
      
    For more information, please see the README.md file.
    )
    ExitApp
}

; ===================================================================
; INITIALIZATION
; ===================================================================
Initialize() {
    ; Create necessary directories
    for _, dir in ["logs", "screenshots", "reports"] {
        if !FileExist(dir)
            FileCreateDir, %dir%
    }
    
    ; Initialize logging
    if (LOG_TO_FILE) {
        FileDelete, %DEBUG_LOG%
        LogMessage("Initializing YouTube Subscriber Bot v" . VERSION, 3)
    }
    
    ; Initialize GUI
    CreateGUI()
    
    ; Load channels if CSV exists
    if (FileExist(CSV_FILE)) {
        LoadChannelsFromCSV(CSV_FILE)
    } else {
        LogMessage("No CSV file found. Please load a CSV file with channel URLs.", 2)
    }
    
    ; Show welcome message
    TrayTip, YouTube Subscriber Bot, Bot initialized and ready to start!, 5, 1
    LogMessage("Initialization complete. Ready to start.", 2)
}

; ===================================================================
; LOGGING FUNCTIONS
; ===================================================================
LogMessage(message, level := 1) {
    static logLevels := {1: "ERROR", 2: "INFO ", 3: "DEBUG"}
    
    ; Skip if message level is higher than current log level
    if (level > LOG_LEVEL)
        return
    
    ; Format the log message
    FormatTime, timestamp,, yyyy-MM-dd HH:mm:ss
    logMessage := "[" timestamp "] [" logLevels[level] "] " message
    
    ; Output to console
    OutputDebug, %logMessage%
    
    ; Output to GUI if available
    if (IsObject(ActivityList)) {
        AddActivity(timestamp, logLevels[level], message)
    }
    
    ; Write to log file if enabled
    if (LOG_TO_FILE && level <= LOG_LEVEL) {
        logFile := (level = 1) ? ERROR_LOG : DEBUG_LOG
        FileAppend, %logMessage%`n, %logFile%
    }
    
    ; Show error messages in a message box
    if (level = 1) {
        MsgBox, 16, Error, %message%
    }
}

; ===================================================================
; UTILITY FUNCTIONS
; ===================================================================
LoadChannelsFromCSV(filePath) {
    try {
        FileRead, csvData, %filePath%
        if (!csvData) {
            throw "CSV file is empty or could not be read."
        }
        
        ; Parse CSV data
        channels := []
        Loop, Parse, csvData, `n, `r
        {
            if (A_Index = 1)  ; Skip header row
                continue
                
            StringSplit, fields, A_LoopField, `,
            if (fields0 >= 2) {
                channels.Push({"title": fields1, "url": fields2})
            }
        }
        
        ; Update GUI
        GuiControl,, SubCount, % channels.Length()
        LogMessage("Loaded " . channels.Length() . " channels from " . filePath, 2)
        
        return channels
    } catch e {
        LogMessage("Error loading CSV file: " . e, 1)
        return []
    }
}

; ===================================================================
; MAIN SCRIPT EXECUTION
; ===================================================================
; The script execution starts here
#SingleInstance, Force
#NoEnv
#Persistent

; Set up tray menu
Menu, Tray, NoStandard
Menu, Tray, Add, &Start, StartBot
Menu, Tray, Add, &Pause, PauseBot
Menu, Tray, Add, &Resume, ResumeBot
Menu, Tray, Add, &Exit, ExitBot
Menu, Tray, Default, &Start
Menu, Tray, Tip, YouTube Subscriber Bot %VERSION%


; Start the application
#Include %A_ScriptDir%\youtube_subscriber_enhanced.ahk

; Start the bot if no command line arguments
if (A_Args.Length() = 0) {
    Initialize()
}

return

; ===================================================================
; HOTKEYS
; ===================================================================
^!s::  ; Ctrl+Alt+S - Start the bot
    StartBot()
return

^!p::  ; Ctrl+Alt+P - Pause the bot
    PauseBot()
return

^!r::  ; Ctrl+Alt+R - Resume the bot
    ResumeBot()
return

^!x::  ; Ctrl+Alt+X - Exit the bot
    ExitBot()
return

; ===================================================================
; TRAY MENU HANDLERS
; ===================================================================
StartBot() {
    if (!IS_RUNNING) {
        IS_RUNNING := true
        IS_PAUSED := false
        LogMessage("Bot started", 2)
        TrayTip, YouTube Subscriber Bot, Bot started, 2, 1
        SetTimer, ProcessChannels, 1000
    }
}

PauseBot() {
    if (IS_RUNNING && !IS_PAUSED) {
        IS_PAUSED := true
        LogMessage("Bot paused", 2)
        TrayTip, YouTube Subscriber Bot, Bot paused, 2, 1
    }
}

ResumeBot() {
    if (IS_RUNNING && IS_PAUSED) {
        IS_PAUSED := false
        LogMessage("Bot resumed", 2)
        TrayTip, YouTube Subscriber Bot, Bot resumed, 2, 1
    }
}

ExitBot() {
    LogMessage("Bot stopped by user", 2)
    TrayTip, YouTube Subscriber Bot, Bot stopped, 2, 1
    Sleep, 2000
    ExitApp
}

; ===================================================================
; MAIN PROCESSING LOOP
; ===================================================================
ProcessChannels:
    if (!IS_RUNNING || IS_PAUSED)
        return
        
    ; Process channels here
    ; ...
    
    ; Update status
    GuiControl,, StatusText, Running... (%A_Index% processed)
    
    ; Random delay between actions
    Random, delay, %MIN_DELAY%, %MAX_DELAY%
    Sleep, %delay%
return
CSV_FILE := "subscriptions.csv"  ; Input CSV file with channel URLs
LOG_FILE := "subscription_log.csv"  ; Output log file
DETAILED_LOG := "detailed_log.txt"  ; Detailed log with error codes
SESSION_FILE := "session.txt"  ; Session save file
BROWSER := "Chrome"  ; Browser to use (Chrome or Firefox)
USE_PROXY := false  ; Set to true to use proxy
PROXY_SERVER := "socks5://localhost:1080"  ; Proxy server address

; === GLOBAL VARIABLES ===
knownChannels := {}
totalChannels := 0
processedCount := 0
SUBSCRIBE_X := 1200  ; Default X coordinate for subscribe button
SUBSCRIBE_Y := 700   ; Default Y coordinate for subscribe button
currentChannel := ""

; === INITIALIZATION ===
OnMessage(0x401, "WM_ERROR")  ; Handle network errors
OnExit("Cleanup")

; === MAIN FUNCTION ===
Main() {
    ; Detect screen resolution and adjust coordinates
    DetectResolution()
    
    ; Read CSV file
    if !FileExist(CSV_FILE) {
        MsgBox, 16, Error, CSV file not found: %CSV_FILE%
        ExitApp
    }
    
    ; Count total channels
    totalChannels := CountCSVLines(CSV_FILE) - 1  ; Subtract header row
    
    ; Check for resume session
    ResumeSession()
    
    ; Launch browser
    LaunchBrowser()
    
    ; Login to YouTube
    LoginToYouTube()
    
    ; Show progress window
    ShowProgress(totalChannels)
    
    ; Process each channel from CSV
    channelIndex := 0
    Loop, read, %CSV_FILE%
    {
        if (A_Index = 1) {  ; Skip header row
            continue
        }
            
        channelIndex++
        
        ; Skip already processed channels if resuming
        if (processedCount > 0 && channelIndex <= processedCount) {
            continue
        }
        
        ; Parse CSV line
        StringSplit, fields, A_LoopReadLine, `,, %A_Space%%A_Tab%
        channelTitle := fields1
        channelUrl := fields2
        
        ; Update current channel for session tracking
        currentChannel := channelUrl
        processedCount := channelIndex
        
        ; Update progress GUI
        UpdateProgress(channelIndex, totalChannels)
        
        ; Subscribe to channel
        SubscribeToChannel(channelTitle, channelUrl)
        
        ; Save session
        SaveSession()
        
        ; Rate limiting to avoid detection
        RateLimit()
    }
    
    MsgBox, 64, Success, Subscription process completed!
    ExitApp
}

; === BROWSER FUNCTIONS ===
LaunchBrowser() {
    if BROWSER = "Chrome" {
        if (USE_PROXY) {
            Run, chrome.exe --proxy-server="%PROXY_SERVER%"
        } else {
            Run, chrome.exe
        }
    } else if BROWSER = "Firefox" {
        Run, firefox.exe
    }
    
    WinWait, ahk_exe chrome.exe,, 10
    if ErrorLevel {
        LogWithDetails("System", "Browser", "Failed to launch browser", 1001)
        MsgBox, 16, Error, Failed to launch browser!
        ExitApp
    }
    
    Sleep, 2000
}

; === LOGIN FUNCTION ===
LoginToYouTube() {
    WinActivate, ahk_exe chrome.exe
    Sleep, 1000
    
    ; Navigate to YouTube
    Send, ^l
    Sleep, 500
    Send, https://www.youtube.com/{Enter}
    Sleep, 5000
    
    ; Check if already logged in
    if WinExist("ahk_class Chrome_WidgetWin_1") {
        WinActivate, ahk_class Chrome_WidgetWin_1
        Send, ^t
        Sleep, 1000
        Send, https://www.youtube.com/account{Enter}
        Sleep, 2000
        
        ; Use image recognition to check if logged in
        if !IsLoggedIn() {
            ; Not logged in - need to sign in
            Send, ^l
            Sleep, 500
            Send, https://accounts.google.com/signin/v2/identifier?service=youtube{Enter}
            Sleep, 2000
            
            ; Wait for email input
            Sleep, 2000
            Send, your-email@gmail.com{Tab}{Enter}
            Sleep, 2000
            
            ; Wait for password input
            Sleep, 2000
            Send, your-password{Enter}
            Sleep, 5000
            
            ; Verify login was successful
            if !IsLoggedIn() {
                LogWithDetails("System", "Login", "Failed to login", 1002)
                MsgBox, 16, Error, Failed to login to YouTube!
                ExitApp
            }
        }
    }
    
    LogWithDetails("System", "Login", "Successfully logged in", 0)
}

; === SUBSCRIBE FUNCTION ===
SubscribeToChannel(title, url) {
    ; Navigate to channel
    WinActivate, ahk_exe chrome.exe
    Sleep, 500
    Send, ^l
    Sleep, 500
    Send, %url%{Enter}
    Sleep, 3000
    
    ; Check if already subscribed
    if knownChannels.HasKey(title) {
        LogWithDetails(title, url, "Already Subscribed", 0)
        return
    }
    
    ; Try multiple methods to find subscribe button
    subscribeFound := false
    
    ; Method 1: Image search (works for both themes)
    if ImageSearchSubscribeButton() {
        subscribeFound := true
        Click, %FoundX%, %FoundY%
        Sleep, 1000
    }
    
    ; Method 2: New theme detection (left side)
    if !subscribeFound {
        ; Try new theme positions
        newThemePositions := [
            {x: 100, y: 200},  ; Top left
            {x: 100, y: 300},  ; Middle left
            {x: 100, y: 400},  ; Lower left
            {x: 100, y: 500},  ; Bottom left
            {x: 100, y: 600},  ; Bottom left
            {x: 100, y: 700},  ; Bottom left
            {x: 100, y: 800},  ; Bottom left
            {x: 100, y: 900},  ; Bottom left
            {x: 100, y: 1000}  ; Bottom left
        ]
        
        Loop, %newThemePositions.MaxIndex% {
            pos := newThemePositions[A_Index]
            if IsSubscribeButtonPresent(pos.x, pos.y) {
                subscribeFound := true
                Click, %pos.x%, %pos.y%
                Sleep, 1000
                break
            }
        }
    }
    
    ; Method 3: Old theme detection (right side)
    if !subscribeFound {
        ; Try old theme positions
        oldThemePositions := [
            {x: 1200, y: 700},  ; Default old theme
            {x: 1100, y: 700},  ; Slightly left
            {x: 1300, y: 700},  ; Slightly right
            {x: 1200, y: 600},  ; Slightly up
            {x: 1200, y: 800},  ; Slightly down
        ]
        
        Loop, %oldThemePositions.MaxIndex% {
            pos := oldThemePositions[A_Index]
            if IsSubscribeButtonPresent(pos.x, pos.y) {
                subscribeFound := true
                Click, %pos.x%, %pos.y%
                Sleep, 1000
                break
            }
        }
    }
    
    ; Method 4: Search for "Subscribe" text
    if !subscribeFound {
        ; Look for "Subscribe" text using OCR
        ; This requires Tesseract OCR installed
        if IsSubscribeTextPresent() {
            subscribeFound := true
            Click, %FoundX%, %FoundY%
            Sleep, 1000
        }
    }
    
    ; Verify subscription
    if (subscribeFound) {
        ; Check multiple ways to verify subscription
        if !IsSubscribeButtonPresent(SUBSCRIBE_X, SUBSCRIBE_Y) {
            ; Check new theme positions
            Loop, %newThemePositions.MaxIndex% {
                pos := newThemePositions[A_Index]
                if !IsSubscribeButtonPresent(pos.x, pos.y) {
                    knownChannels[title] := true
                    LogWithDetails(title, url, "Subscribed", 0)
                    return
                }
            }
            
            ; Check old theme positions
            Loop, %oldThemePositions.MaxIndex% {
                pos := oldThemePositions[A_Index]
                if !IsSubscribeButtonPresent(pos.x, pos.y) {
                    knownChannels[title] := true
                    LogWithDetails(title, url, "Subscribed", 0)
                    return
                }
            }
        }
        
        ; If still not verified, try image search again
        if ImageSearchSubscribeButton() {
            knownChannels[title] := true
            LogWithDetails(title, url, "Subscribed", 0)
            return
        }
    }
    
    ; If we couldn't subscribe or verify
    if (subscribeFound) {
        LogWithDetails(title, url, "Failed to verify subscription", 1003)
    } else {
        LogWithDetails(title, url, "Subscribe Button Not Found", 1004)
    }
}

; === SUBSCRIPTION DETECTION FUNCTIONS ===
IsSubscribeButtonPresent(x, y) {
    ; Check multiple pixels around the given coordinates
    coords := [
        {x: x, y: y},
        {x: x+50, y: y},
        {x: x-50, y: y},
        {x: x, y: y+50},
        {x: x, y: y-50}
    ]
    
    Loop, %coords.MaxIndex% {
        pos := coords[A_Index]
        color := PixelGetColor(pos.x, pos.y)
        
        ; Check for both old and new theme colors
        if (IsRedColor(color) || IsBlueColor(color))
            return true
    }
    return false
}

IsRedColor(color) {
    ; YouTube old theme subscribe button color
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    return (r > 200 && g < 50 && b < 50)
}

IsBlueColor(color) {
    ; YouTube new theme subscribe button color
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    return (r < 50 && g < 50 && b > 200)
}

IsSubscribeTextPresent() {
    ; This requires Tesseract OCR installed
    ; Look for "Subscribe" text in multiple areas
    searchAreas := [
        {x1: 50, y1: 50, x2: 200, y2: 200},
        {x1: 50, y1: 200, x2: 200, y2: 400},
        {x1: 50, y1: 400, x2: 200, y2: 600},
        {x1: 50, y1: 600, x2: 200, y2: 800},
        {x1: 50, y1: 800, x2: 200, y2: 1000}
    ]
    
    Loop, %searchAreas.MaxIndex% {
        area := searchAreas[A_Index]
        ; Use OCR to search for "Subscribe" text
        ; Implementation depends on OCR library used
        ; This is a placeholder for actual OCR implementation
        if (FindText("Subscribe", area.x1, area.y1, area.x2, area.y2)) {
            global FoundX := (area.x1 + area.x2) / 2
            global FoundY := (area.y1 + area.y2) / 2
            return true
        }
    }
    return false
}

; === UTILITY FUNCTIONS ===
IsSubscribeButtonPresent() {
    ; Check multiple possible locations for the subscribe button
    color1 := PixelGetColor(SUBSCRIBE_X, SUBSCRIBE_Y)
    color2 := PixelGetColor(SUBSCRIBE_X + 50, SUBSCRIBE_Y)
    color3 := PixelGetColor(SUBSCRIBE_X - 50, SUBSCRIBE_Y)
    
    ; Analyze colors - looking for typical YouTube red button
    if (IsRedColor(color1) || IsRedColor(color2) || IsRedColor(color3))
        return true
    return false
}

IsRedColor(color) {
    ; Extract RGB values
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    
    ; Check if it's in the red spectrum (YouTube subscribe button)
    return (r > 200 && g < 50 && b < 50)
}

IsLoggedIn() {
    ; Look for avatar image in top right
    ImageSearch, x, y, A_ScreenWidth-100, 0, A_ScreenWidth, 100, *50 %A_ScriptDir%\avatar.png
    return (ErrorLevel = 0)
}

ImageSearchSubscribeButton() {
    global FoundX, FoundY
    ImageSearch, FoundX, FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *50 %A_ScriptDir%\subscribe_button.png
    return (ErrorLevel = 0)
}

DetectResolution() {
    SysGet, Monitor, MonitorWorkArea, 0
    screenWidth := MonitorRight - MonitorLeft
    screenHeight := MonitorBottom - MonitorTop
    
    ; Adjust coordinates based on resolution
    if (screenWidth < 1920) {
        ; Adjust for smaller screens
        global SUBSCRIBE_X := Floor(screenWidth * 0.625)  ; 1200/1920 = 0.625
        global SUBSCRIBE_Y := Floor(screenHeight * 0.648)  ; 700/1080 = 0.648
    } else {
        ; Default for larger screens
        global SUBSCRIBE_X := 1200
        global SUBSCRIBE_Y := 700
    }
}

CountCSVLines(filename) {
    lineCount := 0
    Loop, Read, %filename%
        lineCount++
    return lineCount
}

RateLimit() {
    ; Add rate limiting to avoid detection
    Random, delay, 30000, 60000  ; 30-60 seconds between subscriptions
    Sleep, %delay%
    
    ; Random mouse movements
    Random, x, 100, A_ScreenWidth-100
    Random, y, 100, A_ScreenHeight-100
    MouseMove, %x%, %y%
}

; === GUI FUNCTIONS ===
ShowProgress(totalChannels) {
    Gui, +AlwaysOnTop
    Gui, Add, Text,, Channels Processed:
    Gui, Add, Text, vProgressText, 0/%totalChannels%
    Gui, Add, Progress, w300 h20 vProgressBar Range0-%totalChannels%
    Gui, Add, Text, vCurrentChannel w300, Current: 
    Gui, Show, x100 y100 h150 w350, YouTube Subscription Progress
}

UpdateProgress(current, total) {
    GuiControl,, ProgressText, %current%/%total%
    GuiControl,, ProgressBar, %current%
    GuiControl,, CurrentChannel, Current: %currentChannel%
}

; === SESSION MANAGEMENT ===
SaveSession() {
    FileDelete, %SESSION_FILE%
    FileAppend, %A_Now%`n%currentChannel%`n%processedCount%, %SESSION_FILE%
}

ResumeSession() {
    global processedCount
    if FileExist(SESSION_FILE) {
        FileRead, sessionData, %SESSION_FILE%
        StringSplit, sessionArray, sessionData, `n
        
        if (sessionArray0 >= 3) {
            processedCount := sessionArray3
            MsgBox, 36, Resume Session, Found previous session with %processedCount% channels processed. Resume?
            IfMsgBox Yes
                return
        }
    }
    processedCount := 0
}

; === LOGGING FUNCTIONS ===
LogWithDetails(title, url, status, errorCode=0) {
    ; Standard log
    LogSubscription(title, url, status)
    
    ; Detailed log
    FormatTime, timestamp,, yyyy-MM-dd HH:mm:ss
    FileAppend, %timestamp% | %title% | %url% | %status% | Error: %errorCode%`n, %DETAILED_LOG%
}

LogSubscription(title, url, status) {
    ; Create log file if it doesn't exist
    if !FileExist(LOG_FILE) {
        FileAppend, Channel Title,Channel URL,Status,Time`n, %LOG_FILE%
    }
    
    ; Add new entry
    FormatTime, timestamp,, yyyy-MM-dd HH:mm:ss
    FileAppend, %title%,%url%,%status%,%timestamp%`n, %LOG_FILE%
}

; === ERROR HANDLING ===
WM_ERROR(wParam, lParam) {
    MsgBox, 16, Error, Network error detected. Please check your connection.
    LogWithDetails("System", "Network", "Network Error", 1005)
    ExitApp
}

Cleanup() {
    ; Save current session
    SaveSession()
    
    ; Close browser if exiting
    MsgBox, 36, Confirm Exit, Close browser?
    IfMsgBox Yes
    {
        if WinExist("ahk_exe chrome.exe")
            WinClose, ahk_exe chrome.exe
    }
}

; === START SCRIPT ===
Main()
