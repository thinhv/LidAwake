# LidAwake

A tiny macOS menu bar app that keeps your Mac awake with the lid closed.

It toggles `pmset -a disablesleep` (macOS asks for your admin password each time). The screen still turns off when you close the lid; the Mac keeps running.

## Install

1. Download `LidAwake-x.y.z.dmg` from [Releases](../../releases) and drag **LidAwake** to Applications.
2. The app is not notarized, so the first launch is blocked. Right-click the app → **Open**, or run:
   ```bash
   xattr -dr com.apple.quarantine /Applications/LidAwake.app
   ```

## Use

Click the laptop icon in the menu bar → **Stay Awake with Lid Closed**. The icon becomes a coffee cup while it's on. Choose **Allow Sleep (normal)** to turn it off.

**Launch at Login** is in the same menu.

> The setting stays on even after you quit the app. Turn it off before putting your Mac in a bag, or it can overheat.

## Build

Requires Xcode command line tools. Supports macOS 13+, Apple Silicon and Intel.

```bash
VERSION=1.0.0 ./build.sh   # → build/LidAwake.app and build/LidAwake-1.0.0.dmg
```
