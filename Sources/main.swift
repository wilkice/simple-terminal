import AppKit
import GhosttyKit

// This object outlives libghostty's callbacks and owns its app/config handles.
final class TerminalApp: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var app: ghostty_app_t?
    private var config: ghostty_config_t?
    private var window: NSWindow?
    private var terminal: TerminalView?

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            try start()
        } catch {
            fputs("Simple Terminal: \(error)\n", stderr)
            NSApp.terminate(nil)
        }
    }

    private func start() throws {
        guard let resources = Bundle.main.resourceURL else { throw StartupError.resources }
        // Set these before ghostty_init snapshots the process environment.
        setenv("GHOSTTY_RESOURCES_DIR", resources.appendingPathComponent("ghostty").path, 1)
        setenv("TERMINFO", resources.appendingPathComponent("terminfo").path, 1)
        guard ghostty_init(UInt(CommandLine.argc), CommandLine.unsafeArgv) == 0 else {
            throw StartupError.initialize
        }
        guard let config = ghostty_config_new() else { throw StartupError.config }
        self.config = config
        // Defaults only: this demo does not load the user's Ghostty settings.
        ghostty_config_finalize(config)
        var callbacks = ghostty_runtime_config_s()
        callbacks.userdata = Unmanaged.passUnretained(self).toOpaque()
        callbacks.wakeup_cb = { pointer in
            guard let pointer else { return }
            let owner = Unmanaged<TerminalApp>.fromOpaque(pointer).takeUnretainedValue()
            DispatchQueue.main.async {
                if let app = owner.app { ghostty_app_tick(app) }
            }
        }
        callbacks.action_cb = { _, _, action in
            switch action.tag {
            case GHOSTTY_ACTION_QUIT, GHOSTTY_ACTION_CLOSE_WINDOW, GHOSTTY_ACTION_SHOW_CHILD_EXITED:
                // Never free a surface while a libghostty callback is on the stack.
                DispatchQueue.main.async { NSApp.terminate(nil) }
                return true
            default:
                return false
            }
        }
        callbacks.read_clipboard_cb = { _, _, _, _, _, _ in GHOSTTY_CLIPBOARD_READ_UNSUPPORTED }
        callbacks.confirm_read_clipboard_cb = { pointer, _, state, _ in
            guard let pointer else { return }
            let view = Unmanaged<TerminalView>.fromOpaque(pointer).takeUnretainedValue()
            if let surface = view.surface { ghostty_surface_deny_clipboard_request(surface, state) }
        }
        callbacks.write_clipboard_cb = { _, _, _, _, _ in }
        callbacks.close_surface_cb = { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
        guard let app = ghostty_app_new(&callbacks, config) else { throw StartupError.app }
        self.app = app

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        self.window = window
        window.title = "Simple Terminal"
        window.isReleasedWhenClosed = false
        window.delegate = self
        let view = TerminalView(frame: NSRect(x: 0, y: 0, width: 900, height: 600))
        terminal = view
        window.contentView = view
        window.center()
        try view.createSurface(app: app)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(view)
        NSApp.activate(ignoringOtherApps: true)
        ghostty_app_set_focus(app, true)
        ghostty_surface_set_focus(view.surface, true)
        ghostty_app_tick(app)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        if let app { ghostty_app_set_focus(app, true) }
    }

    func applicationDidResignActive(_ notification: Notification) {
        if let app { ghostty_app_set_focus(app, false) }
    }

    func windowDidBecomeKey(_ notification: Notification) {
        if let surface = terminal?.surface { ghostty_surface_set_focus(surface, true) }
    }

    func windowDidResignKey(_ notification: Notification) {
        if let surface = terminal?.surface { ghostty_surface_set_focus(surface, false) }
    }

    func windowWillClose(_ notification: Notification) { NSApp.terminate(nil) }

    func applicationWillTerminate(_ notification: Notification) {
        terminal?.closeSurface()
        if let app { ghostty_app_free(app) }
        app = nil
        if let config { ghostty_config_free(config) }
        config = nil
    }
}

enum StartupError: Error { case resources, initialize, config, app, surface, command }

// AppKit view is the adapter; libghostty attaches its own Metal renderer to it.
final class TerminalView: NSView {
    private(set) var surface: ghostty_surface_t?
    private var command: UnsafeMutablePointer<CChar>?
    override var acceptsFirstResponder: Bool { true }

    func createSurface(app: ghostty_app_t) throws {
        wantsLayer = true
        var options = ghostty_surface_config_new()
        options.platform_tag = GHOSTTY_PLATFORM_MACOS
        options.platform.macos.nsview = Unmanaged.passUnretained(self).toOpaque()
        options.userdata = Unmanaged.passUnretained(self).toOpaque()
        options.scale_factor = Double(window?.backingScaleFactor ?? 1)
        // This pinned API treats command as a shell string and forces its
        // wait-after-command mode. SHOW_CHILD_EXITED above terminates immediately.
        // On macOS libghostty prepends "exec -l" itself. Supply only the
        // shell command; another "exec" would be treated as an executable.
        guard let command = strdup("/bin/zsh -il") else { throw StartupError.command }
        self.command = command
        options.command = UnsafePointer(command)
        // The pinned API can retain the command pointer for its I/O thread.
        // Keep it alive until surface teardown; the working directory is copied.
        surface = NSHomeDirectory().withCString { directory in
            options.working_directory = directory
            return ghostty_surface_new(app, &options)
        }
        guard surface != nil else { throw StartupError.surface }
        updateGeometry()
    }

    func closeSurface() {
        if let surface { ghostty_surface_free(surface) }
        surface = nil
        free(command)
        command = nil
    }

    override func layout() {
        super.layout()
        updateGeometry()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        updateGeometry()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateGeometry()
    }

    private func updateGeometry() {
        guard let surface else { return }
        let scale = Double(window?.backingScaleFactor ?? 1)
        ghostty_surface_set_content_scale(surface, scale, scale)
        let pixels = convertToBacking(bounds).size
        ghostty_surface_set_size(surface, UInt32(max(1, pixels.width.rounded())),
                                 UInt32(max(1, pixels.height.rounded())))
        if let number = window?.screen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            ghostty_surface_set_display_id(surface, number.uint32Value)
        }
    }

    override func keyDown(with event: NSEvent) {
        sendKey(event, action: event.isARepeat ? GHOSTTY_ACTION_REPEAT : GHOSTTY_ACTION_PRESS)
    }

    override func keyUp(with event: NSEvent) { sendKey(event, action: GHOSTTY_ACTION_RELEASE) }

    private func sendKey(_ event: NSEvent, action: ghostty_input_action_e) {
        guard let surface else { return }
        var key = ghostty_input_key_s()
        key.action = action
        key.keycode = UInt32(event.keyCode)
        key.mods = modifiers(event.modifierFlags)
        key.consumed_mods = modifiers(event.modifierFlags.subtracting([.control, .command]))
        key.unshifted_codepoint = event.characters(byApplyingModifiers: [])?.unicodeScalars.first?.value ?? 0
        // Send printable characters alongside the physical key; libghostty
        // encodes control keys and escape sequences. No IME adapter in this demo.
        let characters = event.characters(byApplyingModifiers: event.modifierFlags.subtracting(.control)) ?? ""
        let text = characters.unicodeScalars.contains { $0.value < 0x20 || (0xF700...0xF8FF).contains($0.value) }
            ? "" : characters
        text.withCString { pointer in
            key.text = text.isEmpty ? nil : pointer
            _ = ghostty_surface_key(surface, key)
        }
    }

    private func modifiers(_ flags: NSEvent.ModifierFlags) -> ghostty_input_mods_e {
        var bits: UInt32 = 0
        for (flag, value) in [(NSEvent.ModifierFlags.shift, GHOSTTY_MODS_SHIFT),
                              (.control, GHOSTTY_MODS_CTRL), (.option, GHOSTTY_MODS_ALT),
                              (.command, GHOSTTY_MODS_SUPER), (.capsLock, GHOSTTY_MODS_CAPS)] {
            if flags.contains(flag) { bits |= value.rawValue }
        }
        return ghostty_input_mods_e(rawValue: bits)
    }
}

let application = NSApplication.shared
let delegate = TerminalApp()
application.setActivationPolicy(.regular)
application.delegate = delegate
application.run()
