import Foundation
import XCTest
import MidnamKit
@testable import CherryPickerCore

/// Pestaña Device (T-020) sobre el fichero sintético de BankEditingTests: modo «Modo» con el canal 1 en «Todos» y el
/// 10 en «Drums» (los demás, libres).
final class DeviceEditingTests: XCTestCase {
	var file: MidnamFile!
	var doc: MIDINameDocument { get { file.document } set { file.document = newValue } }
	let master = 1

	override func setUp() {
		file = try! MidnamFile(text: BankEditingTests.midnam)
	}

	var mode: Int { doc.modes(master: master)[0].index }
	func sets(_ mode: Int? = nil) -> [String] {
		doc.channelSets(master: master, mode: mode ?? self.mode).map { "\($0.name) \($0.channelsText)" }
	}
	func setIndex(_ name: String) -> Int { doc.channelSets(master: master).first { $0.name == name }!.index }

	func testChannelsText() throws {
		XCTAssertEqual(try parseChannels("1-7, 9, 11-16"), Array(1...7) + [9] + Array(11...16))
		XCTAssertEqual(try parseChannels(" 3 - 1 ,5,5"), [1, 2, 3, 5])
		XCTAssertEqual(try parseChannels(""), [])
		for bad in ["0", "17", "a", "1-2-3", "-4"] {
			XCTAssertThrowsError(try parseChannels(bad), bad)
		}
		XCTAssertEqual(formatChannels(Array(1...7) + [9] + Array(11...16)), "1-7, 9, 11-16")
		XCTAssertEqual(formatChannels([10]), "10")
	}

	func testReadDevice() {
		XCTAssertEqual(doc.deviceNames(master: master).manufacturer, "Prueba")
		XCTAssertEqual(doc.deviceNames(master: master).model, "P-1")
		XCTAssertEqual(doc.modes(master: master).map(\.name), ["Modo"])
		XCTAssertEqual(sets(), ["Todos 1", "Drums 10"])
		XCTAssertEqual(doc.channelSets(master: master, mode: mode)[1].auditionChannel, 10)
		XCTAssertEqual(doc.freeChannels(master: master, mode: mode), Array(2...9) + Array(11...16))
	}

	func testActiveChannels() throws {
		try doc.setActiveChannels(master: master, mode: mode, set: setIndex("Todos"), text: "1-9, 11-16")
		XCTAssertEqual(sets(), ["Todos 1-9, 11-16", "Drums 10"])
		XCTAssertEqual(doc.freeChannels(master: master, mode: mode), [])
		XCTAssertThrowsError(try doc.setActiveChannels(master: master, mode: mode, set: setIndex("Drums"), text: "9-10")) {
			XCTAssertEqual($0 as? DeviceEditError, .channelsInUse([9]))
		}
		XCTAssertThrowsError(try doc.setActiveChannels(master: master, mode: mode, set: setIndex("Drums"), text: " ")) {
			XCTAssertEqual($0 as? DeviceEditError, .noChannels)
		}
		// AvailableForChannels con los 16 canales, como los ficheros de CherryPicker.
		XCTAssertTrue(file.text().contains("<AvailableChannel Channel=\"10\" Available=\"false\" />"))
		XCTAssertThrowsError(try doc.addChannelSet(master: master, mode: mode)) {
			XCTAssertEqual($0 as? DeviceEditError, .noFreeChannels)
		}
	}

	/// P13: el Channel Set nuevo lleva un banco vacío; usa todos los canales libres.
	func testAddChannelSet() throws {
		try doc.setActiveChannels(master: master, mode: mode, set: setIndex("Todos"), text: "1-8")
		try doc.addChannelSet(master: master, mode: mode)
		XCTAssertEqual(sets(), ["Todos 1-8", "Drums 10", "New Channel Set 9, 11-16"])
		XCTAssertEqual(BankRows.rows(doc).last.map { "\($0.channelSet):\($0.name) \($0.kind)" }, "New Channel Set:New Bank empty")
		XCTAssertThrowsError(try doc.addChannelSet(master: master, mode: mode))
	}

	func testRename() throws {
		try doc.renameChannelSet(master: master, set: setIndex("Drums"), to: "Bateria")
		XCTAssertEqual(sets(), ["Todos 1", "Bateria 10"])
		XCTAssertTrue(file.text().contains("NameSet=\"Bateria\""))
		XCTAssertThrowsError(try doc.renameChannelSet(master: master, set: setIndex("Bateria"), to: "Todos")) {
			XCTAssertEqual($0 as? DeviceEditError, .duplicateChannelSetName("Todos"))
		}
		try doc.renameMode(master: master, mode: mode, to: "Multi")
		XCTAssertEqual(doc.modes(master: master).map(\.name), ["Multi"])
		XCTAssertThrowsError(try doc.renameMode(master: master, mode: mode, to: " ")) {
			XCTAssertEqual($0 as? DeviceEditError, .emptyName)
		}
	}

	func testAddAndDeleteMode() throws {
		XCTAssertThrowsError(try doc.deleteMode(master: master, mode: mode)) { XCTAssertEqual($0 as? DeviceEditError, .lastMode) }
		let new = try doc.addMode(master: master)
		XCTAssertEqual(doc.modes(master: master).map(\.name), ["Modo", "New Mode"])
		XCTAssertEqual(sets(new), ["New Channel Set 1-16"])
		XCTAssertEqual(sets(), ["Todos 1", "Drums 10"], "el primer modo no cambia")
		try doc.addMode(master: master)
		XCTAssertEqual(doc.modes(master: master).map(\.name), ["Modo", "New Mode", "New Mode 2"])
		XCTAssertEqual(doc.channelSets(master: master).map(\.name), ["Todos", "Drums", "New Channel Set", "New Channel Set 2"])
		// Borrar el modo se lleva su Channel Set, su banco y su lista.
		try doc.deleteMode(master: master, mode: new)
		XCTAssertEqual(doc.modes(master: master).map(\.name), ["Modo", "New Mode 2"])
		XCTAssertEqual(doc.channelSets(master: master).map(\.name), ["Todos", "Drums", "New Channel Set 2"])
		XCTAssertEqual(BankRows.rows(doc).filter { $0.name.hasPrefix("New Bank") }.map(\.name), ["New Bank 2"])
		XCTAssertFalse(file.text().contains("PatchNameList Name=\"New Bank\" "))
	}

	/// − de Channel Set: con patches, sus bancos van a otro (Reassign Banks To); vacío, se borra sin más.
	func testDeleteChannelSet() throws {
		XCTAssertThrowsError(try doc.deleteChannelSet(master: master, mode: mode, set: setIndex("Drums"))) {
			XCTAssertEqual($0 as? DeviceEditError, .reassignTargetNeeded)
		}
		try doc.deleteChannelSet(master: master, mode: mode, set: setIndex("Drums"), reassignTo: setIndex("Todos"))
		XCTAssertEqual(sets(), ["Todos 1"])
		XCTAssertEqual(BankRows.rows(doc).map { "\($0.channelSet):\($0.name)" }, ["Todos:Uno", "Todos:Custom", "Todos:Tres", "Todos:Kits"])
		XCTAssertEqual(doc.freeChannels(master: master, mode: mode).count, 15)
		XCTAssertThrowsError(try doc.deleteChannelSet(master: master, mode: mode, set: setIndex("Todos"))) {
			XCTAssertEqual($0 as? DeviceEditError, .lastChannelSetInMode("Todos"))
		}
		try doc.addChannelSet(master: master, mode: mode)
		try doc.deleteChannelSet(master: master, mode: mode, set: setIndex("New Channel Set"))
		XCTAssertEqual(sets(), ["Todos 1"])
		XCTAssertFalse(file.text().contains("New Bank"))
	}

	/// Tras editar, el fichero sigue valiendo contra la DTD (si están las DTD).
	func testEditedFileIsValid() throws {
		try doc.setActiveChannels(master: master, mode: mode, set: setIndex("Todos"), text: "1-8")
		try doc.addChannelSet(master: master, mode: mode)
		try doc.addMode(master: master)
		try doc.renameChannelSet(master: master, set: setIndex("Drums"), to: "Bateria")
		let text = file.text()
		XCTAssertEqual(try MidnamFile(text: text).document, doc, "ida y vuelta")
		let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../..").standardized
		try XCTSkipUnless(FileManager.default.fileExists(atPath: repo.appendingPathComponent("reference/dtd/MIDIEvents10.dtd").path),
		                  "sin DTD en reference/dtd")
		let url = FileManager.default.temporaryDirectory.appendingPathComponent("deviceediting-\(UUID().uuidString).midnam")
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
		let out = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
		XCTAssertEqual(p.terminationStatus, 0, out)
	}
}
