#!/usr/bin/env pwsh

# Ensure we're running in PowerShell 7.4.3 or later
#Requires -Version 7.4.3

# Function to center text
function Center-Text {
    param([string]$Text)
    $consoleWidth = $Host.UI.RawUI.WindowSize.Width
    $padding = [math]::Max(0, ($consoleWidth - $Text.Length) / 2)
    return " " * [math]::Floor($padding) + $Text
}

# Clear the console
Clear-Host

# ANSI escape codes for formatting
$bold = "`e[1m"
$large = "`e[1m"  # This doesn't actually change size, but makes it bold
$reset = "`e[0m"

# The message
$message = "Hello World"

# Calculate the position to start drawing (centered vertically)
$consoleHeight = $Host.UI.RawUI.WindowSize.Height
$startLine = [math]::Floor(($consoleHeight - 7) / 2)  # 7 is the height of our "large font"

# Move cursor to starting position
[Console]::SetCursorPosition(0, $startLine)

# ASCII art representation of "Hello World"
$asciiArt = @(
    " _   _      _ _        __        __         _     _ ",
    "| | | | ___| | | ___   \ \      / /__  _ __| | __| |",
    "| |_| |/ _ \ | |/ _ \   \ \ /\ / / _ \| '__| |/ _` |",
    "|  _  |  __/ | | (_) |   \ V  V / (_) | |  | | (_| |",
    "|_| |_|\___|_|_|\___/     \_/\_/ \___/|_|  |_|\__,_|"
)

# Display the ASCII art
foreach ($line in $asciiArt) {
    Write-Host ($bold + $large + (Center-Text $line) + $reset)
}

# Add a newline
Write-Host ""

# Display the centered "Hello World" message
Write-Host ($bold + $large + (Center-Text $message) + $reset)

# Move cursor to the bottom of the console
[Console]::SetCursorPosition(0, $consoleHeight - 1)