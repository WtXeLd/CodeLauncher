import SwiftUI
import Carbon

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var keyCode: Int
    @Binding var modifiers: Int
    var onChanged: (() -> Void)?

    func makeNSView(context: Context) -> ShortcutRecorderField {
        let field = ShortcutRecorderField()
        field.onShortcutChanged = { code, mods in
            keyCode = code
            modifiers = mods
            onChanged?()
        }
        field.updateDisplay(keyCode: keyCode, modifiers: modifiers)
        return field
    }

    func updateNSView(_ field: ShortcutRecorderField, context: Context) {
        field.updateDisplay(keyCode: keyCode, modifiers: modifiers)
    }
}

final class ShortcutRecorderField: NSTextField {
    var onShortcutChanged: ((Int, Int) -> Void)?
    private var isRecording = false
    private var localMonitor: Any?

    override init(frame: NSRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        isEditable = false
        isSelectable = false
        isBezeled = true
        bezelStyle = .roundedBezel
        alignment = .center
        font = .systemFont(ofSize: 12)
        cell?.wraps = false
        cell?.isScrollable = false
        placeholderString = "Click to record"
    }

    // Force the same intrinsic height as a Toggle so Form rows stay consistent
    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: 22)
    }

    override func mouseDown(with event: NSEvent) {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        isRecording = true
        stringValue = "Press a key..."
        textColor = .systemOrange

        // Make this window key so the local monitor receives events even in .accessory mode
        window?.makeKey()

        // Unregister Carbon hotkey synchronously — using Task would create a race condition
        // where the hotkey fires before the async block executes
        MainActor.assumeIsolated { HotkeyManager.shared.suspend() }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == 53 { self.stopRecording(); return nil }
            let isFunctionKey = (0x60...0x7F).contains(Int(event.keyCode))
            if !isFunctionKey {
                guard mods.contains(.command) || mods.contains(.control) || mods.contains(.option) else { return nil }
            }
            var carbonMods = 0
            if mods.contains(.command) { carbonMods |= cmdKey }
            if mods.contains(.shift)   { carbonMods |= shiftKey }
            if mods.contains(.option)  { carbonMods |= optionKey }
            if mods.contains(.control) { carbonMods |= controlKey }
            self.onShortcutChanged?(Int(event.keyCode), carbonMods)
            self.stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        textColor = .labelColor
        if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
        MainActor.assumeIsolated { HotkeyManager.shared.resumeAfterRecording() }
    }

    func updateDisplay(keyCode: Int, modifiers: Int) {
        guard !isRecording else { return }
        let s = shortcutDisplayString(keyCode: keyCode, modifiers: modifiers)
        stringValue = s
        placeholderString = "Click to record"
    }
}

func shortcutDisplayString(keyCode: Int, modifiers: Int) -> String {
    guard keyCode >= 0, modifiers >= 0 else { return "" }
    var parts: [String] = []
    if modifiers & controlKey != 0 { parts.append("⌃") }
    if modifiers & optionKey  != 0 { parts.append("⌥") }
    if modifiers & shiftKey   != 0 { parts.append("⇧") }
    if modifiers & cmdKey     != 0 { parts.append("⌘") }
    parts.append(keyName(for: keyCode))
    return parts.joined()
}

private func keyName(for keyCode: Int) -> String {
    let map: [Int: String] = [
        0:"A",1:"S",2:"D",3:"F",4:"H",5:"G",6:"Z",7:"X",8:"C",9:"V",
        11:"B",12:"Q",13:"W",14:"E",15:"R",16:"Y",17:"T",
        18:"1",19:"2",20:"3",21:"4",22:"6",23:"5",24:"=",25:"9",26:"7",
        27:"-",28:"8",29:"0",30:"]",31:"O",32:"U",33:"[",34:"I",35:"P",
        36:"↵",37:"L",38:"J",39:"'",40:"K",41:";",42:"\\",43:",",44:"/",
        45:"N",46:"M",47:".",48:"⇥",49:"Space",50:"`",
        122:"F1",120:"F2",99:"F3",118:"F4",96:"F5",97:"F6",
        98:"F7",100:"F8",101:"F9",109:"F10",103:"F11",111:"F12",
    ]
    return map[keyCode] ?? "Key\(keyCode)"
}
