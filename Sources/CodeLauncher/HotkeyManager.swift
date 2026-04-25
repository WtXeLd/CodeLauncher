import AppKit
import Carbon

let HOTKEY_SIGNATURE: OSType = 0x434C4E43 // "CLNC"
let HOTKEY_ID_PANEL: UInt32 = 1
let DEFAULT_KEY_CODE: UInt32 = 0x01        // kVK_ANSI_S
let DEFAULT_MODIFIERS: UInt32 = UInt32(cmdKey | shiftKey)

private let KEY_CODE_KEY = "hotkeyKeyCode"
private let MODIFIERS_KEY = "hotkeyModifiers"

@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    private init() {}

    private var currentKeyCode: UInt32 {
        let stored = UserDefaults.standard.integer(forKey: KEY_CODE_KEY)
        guard UserDefaults.standard.object(forKey: KEY_CODE_KEY) != nil, stored >= 0 else {
            return DEFAULT_KEY_CODE
        }
        return UInt32(stored)
    }

    private var currentModifiers: UInt32 {
        let stored = UserDefaults.standard.integer(forKey: MODIFIERS_KEY)
        guard UserDefaults.standard.object(forKey: MODIFIERS_KEY) != nil, stored >= 0 else {
            return DEFAULT_MODIFIERS
        }
        return UInt32(stored)
    }

    func register() {
        installEventHandler()
        registerHotKey()
    }

    func update(keyCode: Int, modifiers: Int) {
        UserDefaults.standard.set(keyCode, forKey: KEY_CODE_KEY)
        UserDefaults.standard.set(modifiers, forKey: MODIFIERS_KEY)
        unregisterHotKey()
        guard keyCode >= 0, modifiers >= 0 else { return }
        registerHotKey()
    }

    // Called by ShortcutRecorderField while recording to prevent the current
    // hotkey from firing when the user presses the new combination.
    func suspend() { unregisterHotKey() }
    func resumeAfterRecording() {
        let kc = UserDefaults.standard.integer(forKey: KEY_CODE_KEY)
        let mods = UserDefaults.standard.integer(forKey: MODIFIERS_KEY)
        guard kc >= 0, mods >= 0 else { return }
        registerHotKey()
    }

    func toggle() {
        QuickLaunchWindowController.shared.toggle()
    }

    private func installEventHandler() {
        guard eventHandler == nil else { return }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                var hkID = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID), nil,
                    MemoryLayout<EventHotKeyID>.size, nil, &hkID)
                if hkID.id == HOTKEY_ID_PANEL {
                    Task { @MainActor in HotkeyManager.shared.toggle() }
                }
                return noErr
            },
            1, &eventType, nil, &eventHandler
        )
    }

    private func registerHotKey() {
        let hkID = EventHotKeyID(signature: HOTKEY_SIGNATURE, id: HOTKEY_ID_PANEL)
        RegisterEventHotKey(currentKeyCode, currentModifiers, hkID,
                            GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    private func unregisterHotKey() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref); hotKeyRef = nil }
    }
}
