import SwiftUI
import AppKit
import AVFoundation
import CoreAudio
import CoreGraphics

enum DeviceGroupType {
    case external
    case builtIn

    var title: String {
        switch self {
        case .external: return "External"
        case .builtIn: return "Built-in"
        }
    }

    var icon: String {
        switch self {
        case .external: return "rectangle.connected.to.line.below"
        case .builtIn: return "laptopcomputer"
        }
    }
}

enum ConnectionType {
    case wired
    case wireless
    case internalDevice
    case unknown

    var color: Color {
        switch self {
        case .wired: return .blue
        case .wireless: return .green
        case .internalDevice: return .orange
        case .unknown: return .gray
        }
    }
}

enum DeviceKind {
    case camera
    case microphone
    case speaker
    case display
    case usb
    case bluetooth

    var icon: String {
        switch self {
        case .camera: return "camera"
        case .microphone: return "mic"
        case .speaker: return "speaker.wave.2"
        case .display: return "display"
        case .usb: return "cable.connector"
        case .bluetooth: return "dot.radiowaves.left.and.right"
        }
    }

    var order: Int {
        switch self {
        case .camera: return 0
        case .microphone: return 1
        case .speaker: return 2
        case .display: return 3
        case .usb: return 4
        case .bluetooth: return 5
        }
    }
}

enum TransportType {
    case usb
    case bluetooth
    case hdmi
    case wifi
    case builtIn
    case other

    var icon: String {
        switch self {
        case .usb: return "usb"
        case .bluetooth: return "dot.radiowaves.left.and.right"
        case .hdmi: return "tv"
        case .wifi: return "wifi"
        case .builtIn: return "laptopcomputer"
        case .other: return "link"
        }
    }

    var label: String {
        switch self {
        case .usb: return "USB"
        case .bluetooth: return "Bluetooth"
        case .hdmi: return "HDMI / Display Cable"
        case .wifi: return "Wireless"
        case .builtIn: return "Built-in"
        case .other: return "Other"
        }
    }
}

enum DetailConfidence {
    case exact
    case inferred
}

struct DeviceRow: Identifiable {
    let id = UUID()
    let group: DeviceGroupType
    let kind: DeviceKind
    let transport: TransportType
    let name: String
    let subtitle: String
    let detail: String
    let detailConfidence: DetailConfidence
    let connectionType: ConnectionType
    let isActive: Bool
    let settingsURL: URL?

    var statusColor: Color {
        isActive ? .green : .blue
    }

    var transportTooltip: String {
        detail.isEmpty ? transport.label : "\(transport.label) • \(detail)"
    }
}

struct DeviceGroupSection: Identifiable {
    let id = UUID()
    let type: DeviceGroupType
    let rows: [DeviceRow]

    var title: String { type.title }
    var icon: String { type.icon }
}

@MainActor
final class DeviceStore: ObservableObject {
    @Published var groups: [DeviceGroupSection] = []

    private var timer: Timer?
    private var lastHeavyRefresh: Date = .distantPast

    func start() {
        refreshNow(forceHeavy: true)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshNow(forceHeavy: false)
            }
        }
    }

    func refreshNow(forceHeavy: Bool) {
        let runHeavy = forceHeavy || Date().timeIntervalSince(lastHeavyRefresh) > 10
        Task.detached(priority: .userInitiated) {
            let snapshot = DeviceCollector.collect(runHeavyCollectors: runHeavy)
            await MainActor.run {
                self.groups = snapshot
                if runHeavy {
                    self.lastHeavyRefresh = Date()
                }
            }
        }
    }
}

enum DeviceCollector {
    private static var cachedUSBRows: [DeviceRow] = []
    private static var cachedBluetoothRows: [DeviceRow] = []

    private static let soundSettingsURL = URL(string: "x-apple.systempreferences:com.apple.Sound-Settings.extension")
    private static let bluetoothSettingsURL = URL(string: "x-apple.systempreferences:com.apple.Bluetooth")
    private static let displaySettingsURL = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension")
    private static let cameraPrivacySettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")
    private static let systemInfoURL = URL(fileURLWithPath: "/System/Applications/Utilities/System Information.app")

    static func collect(runHeavyCollectors: Bool) -> [DeviceGroupSection] {
        if runHeavyCollectors {
            let profile = collectSystemProfilerSections()
            cachedUSBRows = profile.usb
            cachedBluetoothRows = profile.bluetooth
        }

        let audio = collectAudioDevices()
        let cameras = collectCameras()
        let displays = collectDisplays()

        let allRows = cachedUSBRows + cachedBluetoothRows + audio.inputs + audio.outputs + cameras + displays

        let builtInRows = allRows
            .filter { $0.group == .builtIn }
            .sorted(by: sortRows)

        let externalRows = allRows
            .filter { $0.group == .external }
            .sorted(by: sortRows)

        return [
            DeviceGroupSection(type: .external, rows: externalRows),
            DeviceGroupSection(type: .builtIn, rows: builtInRows)
        ]
    }

    private static func sortRows(_ lhs: DeviceRow, _ rhs: DeviceRow) -> Bool {
        if lhs.kind.order != rhs.kind.order {
            return lhs.kind.order < rhs.kind.order
        }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    private static func collectSystemProfilerSections() -> (usb: [DeviceRow], bluetooth: [DeviceRow]) {
        let json = runSystemProfilerJSON(dataTypes: ["SPUSBDataType", "SPBluetoothDataType"])
        let usbRows = parseUSBRows(from: json)
        let bluetoothRows = parseBluetoothRows(from: json)
        return (usbRows, bluetoothRows)
    }

    private static func collectDisplays() -> [DeviceRow] {
        var displayCount: UInt32 = 0
        let maxDisplays: UInt32 = 16
        var activeDisplays = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
        CGGetOnlineDisplayList(maxDisplays, &activeDisplays, &displayCount)

        let screensByID = Dictionary(uniqueKeysWithValues: NSScreen.screens.compactMap { screen -> (CGDirectDisplayID, NSScreen)? in
            guard let idNum = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return nil
            }
            return (CGDirectDisplayID(idNum.uint32Value), screen)
        })

        return activeDisplays.prefix(Int(displayCount)).compactMap { id in
            guard CGDisplayIsBuiltin(id) == 0 else { return nil }

            let screen = screensByID[id]
            let displayName = screen?.localizedName ?? "External Display"
            let width = CGDisplayPixelsWide(id)
            let height = CGDisplayPixelsHigh(id)
            let side = inferDisplaySide(screen)
            let detail = "\(side) • Display \(id)"
            let transport = inferDisplayTransport(displayName: displayName)
            return DeviceRow(
                group: .external,
                kind: .display,
                transport: transport,
                name: displayName,
                subtitle: "\(width)x\(height)",
                detail: detail,
                detailConfidence: .inferred,
                connectionType: .wired,
                isActive: true,
                settingsURL: displaySettingsURL
            )
        }
    }

    private static func collectCameras() -> [DeviceRow] {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified
        )

        return discovery.devices.map { device in
            let type: ConnectionType
            let group: DeviceGroupType
            let transport: TransportType
            let subtype: String

            let lowerName = device.localizedName.lowercased()
            if lowerName.contains("facetime") || lowerName.contains("built-in") {
                type = .internalDevice
                group = .builtIn
                transport = .builtIn
                subtype = "Built-in Camera"
            } else if device.position == .unspecified && lowerName.contains("continuity") {
                type = .wireless
                group = .external
                transport = .wifi
                subtype = "Continuity Camera"
            } else {
                type = .wired
                group = .external
                transport = .usb
                subtype = "External Camera"
            }

            let detail = device.modelID.isEmpty ? "Port unknown" : device.modelID
            return DeviceRow(
                group: group,
                kind: .camera,
                transport: transport,
                name: device.localizedName,
                subtitle: subtype,
                detail: detail,
                detailConfidence: .inferred,
                connectionType: type,
                isActive: device.isInUseByAnotherApplication,
                settingsURL: cameraPrivacySettingsURL
            )
        }
    }

    private static func collectAudioDevices() -> (inputs: [DeviceRow], outputs: [DeviceRow]) {
        let allDeviceIDs = getAllAudioDeviceIDs()
        var inputs: [DeviceRow] = []
        var outputs: [DeviceRow] = []

        for deviceID in allDeviceIDs {
            let name = getAudioDeviceName(deviceID: deviceID)
            let transportValue = getAudioTransport(deviceID: deviceID)
            let connection = mapAudioTransportToConnection(transportValue)
            let transport = mapAudioTransportToTransportType(transportValue)
            let transportLabel = mapAudioTransportToLabel(transportValue)
            let isRunning = isAudioDeviceRunningSomewhere(deviceID: deviceID)
            let group: DeviceGroupType = connection == .internalDevice ? .builtIn : .external

            if audioChannelCount(deviceID: deviceID, scope: kAudioDevicePropertyScopeInput) > 0 {
                inputs.append(
                    DeviceRow(
                        group: group,
                        kind: .microphone,
                        transport: transport,
                        name: name,
                        subtitle: connection == .internalDevice ? "Built-in Microphone" : "External Microphone",
                        detail: transportLabel,
                        detailConfidence: .exact,
                        connectionType: connection,
                        isActive: isRunning,
                        settingsURL: soundSettingsURL
                    )
                )
            }

            if audioChannelCount(deviceID: deviceID, scope: kAudioDevicePropertyScopeOutput) > 0 {
                outputs.append(
                    DeviceRow(
                        group: group,
                        kind: .speaker,
                        transport: transport,
                        name: name,
                        subtitle: connection == .internalDevice ? "Built-in Output" : "External Output",
                        detail: transportLabel,
                        detailConfidence: .exact,
                        connectionType: connection,
                        isActive: isRunning,
                        settingsURL: soundSettingsURL
                    )
                )
            }
        }

        return (inputs, outputs)
    }

    private static func getAllAudioDeviceIDs() -> [AudioObjectID] {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var propertySize: UInt32 = 0
        let sizeStatus = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize)
        guard sizeStatus == noErr else { return [] }

        let count = Int(propertySize) / MemoryLayout<AudioObjectID>.size
        var devices = [AudioObjectID](repeating: AudioObjectID(0), count: count)

        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize, &devices)
        guard status == noErr else { return [] }

        return devices
    }

    private static func getAudioDeviceName(deviceID: AudioObjectID) -> String {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var name: CFString = "Unknown Audio Device" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)

        let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, &name)
        return status == noErr ? (name as String) : "Unknown Audio Device"
    }

    private static func audioChannelCount(deviceID: AudioObjectID, scope: AudioObjectPropertyScope) -> Int {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        var propertySize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &propertySize) == noErr else {
            return 0
        }

        let ptr = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(propertySize))
        defer { ptr.deallocate() }

        guard AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, ptr) == noErr else {
            return 0
        }

        let buffers = UnsafeMutableAudioBufferListPointer(ptr)
        return buffers.reduce(0) { $0 + Int($1.mNumberChannels) }
    }

    private static func getAudioTransport(deviceID: AudioObjectID) -> UInt32 {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var value: UInt32 = 0
        var propertySize = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &value)
        return status == noErr ? value : 0
    }

    private static func isAudioDeviceRunningSomewhere(deviceID: AudioObjectID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var value: UInt32 = 0
        var propertySize = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &value)
        return status == noErr && value != 0
    }

    private static func mapAudioTransportToConnection(_ transport: UInt32) -> ConnectionType {
        switch transport {
        case kAudioDeviceTransportTypeBuiltIn:
            return .internalDevice
        case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE, kAudioDeviceTransportTypeAirPlay:
            return .wireless
        case kAudioDeviceTransportTypeUSB,
            kAudioDeviceTransportTypeHDMI,
            kAudioDeviceTransportTypeDisplayPort,
            kAudioDeviceTransportTypePCI,
            kAudioDeviceTransportTypeFireWire,
            kAudioDeviceTransportTypeAggregate:
            return .wired
        default:
            return .unknown
        }
    }

    private static func mapAudioTransportToTransportType(_ transport: UInt32) -> TransportType {
        switch transport {
        case kAudioDeviceTransportTypeBuiltIn:
            return .builtIn
        case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE:
            return .bluetooth
        case kAudioDeviceTransportTypeAirPlay:
            return .wifi
        case kAudioDeviceTransportTypeUSB:
            return .usb
        case kAudioDeviceTransportTypeHDMI, kAudioDeviceTransportTypeDisplayPort:
            return .hdmi
        default:
            return .other
        }
    }

    private static func mapAudioTransportToLabel(_ transport: UInt32) -> String {
        switch transport {
        case kAudioDeviceTransportTypeBuiltIn:
            return "Built-in"
        case kAudioDeviceTransportTypeBluetooth:
            return "Bluetooth"
        case kAudioDeviceTransportTypeBluetoothLE:
            return "Bluetooth LE"
        case kAudioDeviceTransportTypeAirPlay:
            return "AirPlay"
        case kAudioDeviceTransportTypeUSB:
            return "USB"
        case kAudioDeviceTransportTypeHDMI:
            return "HDMI"
        case kAudioDeviceTransportTypeDisplayPort:
            return "DisplayPort"
        case kAudioDeviceTransportTypePCI:
            return "PCI"
        case kAudioDeviceTransportTypeFireWire:
            return "FireWire"
        case kAudioDeviceTransportTypeAggregate:
            return "Aggregate"
        default:
            return "Unknown"
        }
    }

    private static func runSystemProfilerJSON(dataTypes: [String]) -> [String: Any] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["-json"] + dataTypes

        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return [:]
        }

        process.waitUntilExit()

        guard process.terminationStatus == 0 else { return [:] }
        let data = output.fileHandleForReading.readDataToEndOfFile()

        guard let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }

        return jsonObj
    }

    private static func parseUSBRows(from json: [String: Any]) -> [DeviceRow] {
        guard let roots = json["SPUSBDataType"] as? [[String: Any]] else { return [] }

        var rows: [DeviceRow] = []

        func walk(_ node: [String: Any], busHint: String?) {
            let nodeName = (node["_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let thisBus = nodeName?.contains("USB") == true ? nodeName : busHint
            let vendorID = node["vendor_id"] as? String
            let productID = node["product_id"] as? String

            if let name = nodeName,
               vendorID != nil || productID != nil || node["location_id"] != nil {
                let vendor = node["manufacturer"] as? String ?? "USB Device"
                let locationID = node["location_id"] as? String
                let side = inferPortSide(locationID: locationID, busHint: thisBus)
                let detail = "\(side) • \(locationID ?? (thisBus ?? "USB"))"
                rows.append(
                    DeviceRow(
                        group: .external,
                        kind: .usb,
                        transport: .usb,
                        name: name,
                        subtitle: vendor,
                        detail: detail,
                        detailConfidence: .inferred,
                        connectionType: .wired,
                        isActive: false,
                        settingsURL: systemInfoURL
                    )
                )
            }

            if let items = node["_items"] as? [[String: Any]] {
                for child in items {
                    walk(child, busHint: thisBus)
                }
            }
        }

        for root in roots {
            if let items = root["_items"] as? [[String: Any]] {
                for item in items {
                    walk(item, busHint: nil)
                }
            }
        }

        return rows
    }

    private static func parseBluetoothRows(from json: [String: Any]) -> [DeviceRow] {
        guard let roots = json["SPBluetoothDataType"] as? [[String: Any]] else { return [] }
        var rows: [DeviceRow] = []

        func yes(_ value: Any?) -> Bool {
            guard let str = value as? String else { return false }
            return str.lowercased().contains("yes") || str == "attrib_Yes"
        }

        func walk(_ node: [String: Any]) {
            let connected = yes(node["device_connected"]) || yes(node["device_isconnected"])
            let name = (node["_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

            if connected, let name {
                let address = node["device_address"] as? String ?? "Bluetooth"
                let category = node["device_minorType"] as? String ?? "Bluetooth Device"
                rows.append(
                    DeviceRow(
                        group: .external,
                        kind: .bluetooth,
                        transport: .bluetooth,
                        name: name,
                        subtitle: category,
                        detail: address,
                        detailConfidence: .exact,
                        connectionType: .wireless,
                        isActive: false,
                        settingsURL: bluetoothSettingsURL
                    )
                )
            }

            if let children = node["_items"] as? [[String: Any]] {
                for child in children {
                    walk(child)
                }
            }
        }

        for root in roots {
            walk(root)
        }

        return rows
    }

    private static func inferPortSide(locationID: String?, busHint: String?) -> String {
        let bus = busHint?.lowercased() ?? ""
        if bus.contains("left") { return "Left" }
        if bus.contains("right") { return "Right" }

        guard let locationID else { return "Unknown Side" }
        guard let hex = locationID.split(separator: " ").first, hex.hasPrefix("0x") else { return "Unknown Side" }
        guard let value = UInt64(hex.dropFirst(2), radix: 16) else { return "Unknown Side" }

        let controllerNibble = (value & 0x00F0_0000) >> 20
        switch controllerNibble {
        case 0x1, 0x2, 0x3:
            return "Left"
        case 0x4, 0x5, 0x6, 0x7, 0x8, 0x9:
            return "Right"
        default:
            return "Unknown Side"
        }
    }

    private static func inferDisplaySide(_ screen: NSScreen?) -> String {
        guard let screen else { return "Unknown Side" }
        guard let main = NSScreen.screens.first else { return "Unknown Side" }
        if screen.frame.midX < main.frame.midX {
            return "Left"
        }
        if screen.frame.midX > main.frame.midX {
            return "Right"
        }
        return "Unknown Side"
    }

    private static func inferDisplayTransport(displayName: String) -> TransportType {
        let lower = displayName.lowercased()
        if lower.contains("airplay") || lower.contains("wireless") {
            return .wifi
        }
        return .hdmi
    }
}
