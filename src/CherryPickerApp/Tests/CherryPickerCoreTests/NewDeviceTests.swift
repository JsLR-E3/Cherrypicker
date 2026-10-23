import Foundation
import XCTest
import MidnamKit
@testable import CherryPickerCore

/// Asistente Device Setup (T-023).
final class NewDeviceTests: XCTestCase {
	func sets(_ f: MidnamFile) -> [String] {
		let mode = f.document.modes(master: 1)[0].index
		return f.document.channelSets(master: 1, mode: mode).map { "\($0.name) \($0.channelsText)" }
	}

	func testAllChannels() throws {
		let f = try MidnamFile.newDevice(manufacturer: " Roland ", model: "JV-1080 & co", sets: [])
		XCTAssertEqual(f.document.deviceNames(master: 1).manufacturer, "Roland")
		XCTAssertEqual(f.document.deviceNames(master: 1).model, "JV-1080 & co")
		XCTAssertEqual(f.document.modes(master: 1).map(\.name), ["Mode 1"])
		XCTAssertEqual(sets(f), ["Presets 1-16"])
		XCTAssertEqual(BankRows.rows(f.document).map { "\($0.name) \($0.kind)" }, ["New Bank empty"])
		let text = f.text()
		XCTAssertTrue(text.contains("\"http://www.midi.org/dtds/MIDINameDocument10.dtd\""), "DOCTYPE de D-003")
		XCTAssertTrue(text.contains("<Model>JV-1080 &amp; co</Model>"))
		try validate(text)
	}

	/// Ejemplo de Roland del original: canal 10 para la batería.
	func testTwoSets() throws {
		XCTAssertEqual(defaultChannelSets(count: 2), [ChannelSetSpec(name: "Presets", channels: "1-9, 11-16"),
		                                             ChannelSetSpec(name: "Drums", channels: "10")])
		let f = try MidnamFile.newDevice(manufacturer: "Roland", model: "JV", sets: defaultChannelSets(count: 2))
		XCTAssertEqual(sets(f), ["Presets 1-9, 11-16", "Drums 10"])
		XCTAssertEqual(BankRows.rows(f.document).map { "\($0.channelSet):\($0.name)" }, ["Presets:New Bank", "Drums:New Bank 2"])
		try validate(f.text())
	}

	func testErrors() {
		func err(_ m: String, _ mo: String, _ s: [ChannelSetSpec]) -> NewDeviceError? {
			do { _ = try MidnamFile.newDevice(manufacturer: m, model: mo, sets: s); return nil } catch { return error as? NewDeviceError }
		}
		XCTAssertEqual(err(" ", "X", []), .emptyManufacturer)
		XCTAssertEqual(err("A", "", []), .emptyModel)
		XCTAssertEqual(err("A", "B", [.init(name: "A", channels: "1-10"), .init(name: "B", channels: "10-11")]), .overlapping([10]))
		XCTAssertEqual(err("A", "B", [.init(name: "A", channels: "1"), .init(name: "A", channels: "2")]), .duplicateSetName("A"))
		XCTAssertEqual(err("A", "B", [.init(name: "A", channels: "1"), .init(name: "C", channels: "")]), .noChannels("C"))
		XCTAssertEqual(defaultChannelSets(count: 3).last, ChannelSetSpec(name: "Set 3", channels: ""))
	}

	func testMiddevAndCloseMatch() throws {
		let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../..").standardized
		let text = try String(contentsOf: repo.appendingPathComponent("captures/exp014/Cherrypicker.middev"))
		XCTAssertEqual(middevEntries(text).map { "\($0.manufacturer)/\($0.model)" },
		               ["Cherrypicker/CP Canales", "Cherrypicker/CP Patches", "Cherrypicker/CP Zap"])
		XCTAssertEqual(closeMatch("cherryPICKER", in: ["Cherrypicker", "Roland"]), "Cherrypicker")
		XCTAssertNil(closeMatch("Roland", in: ["Cherrypicker", "Roland"]))
		XCTAssertNil(closeMatch("Yamaha", in: ["Roland"]))
	}

	func validate(_ text: String) throws {
		XCTAssertEqual(try MidnamFile(text: text).text(), text, "ida y vuelta")
		let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../..").standardized
		try XCTSkipUnless(FileManager.default.fileExists(atPath: repo.appendingPathComponent("reference/dtd/MIDIEvents10.dtd").path),
		                  "sin DTD en reference/dtd")
		let url = FileManager.default.temporaryDirectory.appendingPathComponent("newdevice-\(UUID().uuidString).midnam")
		try text.write(to: url, atomically: true, encoding: .utf8)
		defer { try? FileManager.default.removeItem(at: url) }
		let p = Process()
		p.executableURL = repo.appendingPathComponent("tools/validar_midnam.sh")
		p.arguments = [url.path]
		let pipe = Pipe()
		p.standardOutput = pipe
		p.standardError = pipe
		try p.run()
		p.waitUntilExit()
		XCTAssertEqual(p.terminationStatus, 0, String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self))
	}
}
