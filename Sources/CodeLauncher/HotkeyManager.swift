import AppKit
import Carbon

private let HOTKEY_SIGNATURE: OSType = 0x434C4E43 // "CLNC"
private let HOTKEY_ID_PANEL: UInt32 = 1
// kVK_ANSI_S = 0x01
private let DEFAULT_KEY_CODE: UInt32 = 0x01
private let DEFAULT_MODIFIERS: UInt32 = UInt32(cmdKey | shiftKey)

@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    private init() {}

    func register() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                var hkID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                if hkID.id == HOTKEY_ID_PANEL {
                    Task { @MainActor in HotkeyManager.shared.toggle() }
                }
                return noErr
            },
            1, &eventType, nil, &eventHandler
        )

        let hkID = EventHotKeyID(signature: HOTKEY_SIGNATURE, id: HOTKEY_ID_PANEL)
        RegisterEventHotKey(DEFAULT_KEY_CODE, DEFAULT_MODIFIERS, hkID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func toggle() {
        QuickLaunchWindowController.shared.toggle()
    }
}
