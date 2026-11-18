import AppKit
import ServiceManagement

// LidAwake: a menu bar toggle for `pmset -a disablesleep`.
// When on, the Mac keeps running with the lid closed (screen still turns off).

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let toggleItem = NSMenuItem(title: "", action: #selector(toggle), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        loginItem.target = self
        menu.addItem(loginItem)
        let about = NSMenuItem(title: "About LidAwake", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit LidAwake", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        menu.delegate = self
        statusItem.menu = menu

        refresh()
    }

    /// Reads the current state from `pmset -g` (the SleepDisabled line is absent when off).
    private func isSleepDisabled() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        task.arguments = ["-g"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do { try task.run() } catch { return false }
        task.waitUntilExit()
        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        return output.split(separator: "\n").contains { line in
            let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
            return parts.count >= 2 && parts[0] == "SleepDisabled" && parts[1] == "1"
        }
    }

    private func refresh() {
        let on = isSleepDisabled()
        let symbol = on ? "laptopcomputer.and.arrow.down" : "laptopcomputer"
        let image = NSImage(systemSymbolName: on ? "cup.and.saucer.fill" : symbol,
                            accessibilityDescription: on ? "Lid sleep off" : "Lid sleep on")
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = on ? "Mac stays awake with lid closed" : "Normal sleep"
        toggleItem.title = on ? "Allow Sleep (normal)" : "Stay Awake with Lid Closed"
        toggleItem.state = on ? .on : .off
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSAlert(error: error).runModal()
        }
        refresh()
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .credits: NSAttributedString(string: "Keeps your Mac awake with the lid closed.\nTurn it off before putting your Mac in a bag.")
        ])
    }

    func menuWillOpen(_ menu: NSMenu) { refresh() }

    @objc private func toggle() {
        let newValue = isSleepDisabled() ? 0 : 1
        // macOS shows its own password prompt; the app never sees the password.
        let script = "do shell script \"/usr/bin/pmset -a disablesleep \(newValue)\" with administrator privileges"
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
        refresh()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // menu bar only, no Dock icon
app.run()
