import Foundation
import XCTest
import MidnamKit
@testable import CherryPickerCore

/// Pestaña Controllers (T-028).
final class ControllersTests: XCTestCase {
	var file: MidnamFile!
	var doc: MIDINameDocument { get { file.document } set { file.document = newValue } }
	var master: Int { BankRows.rows(doc)[0].ref.master }
	var todos: Int { BankRows.rows(doc)[0].ref.set }
	var drums: Int { BankRows.rows(doc).last!.ref.set }

	override func setUp() {
		file = try! MidnamFile(text: BankEditingTests.midnam)
	}

	func setItems(_ set: Int) -> [ChannelNameSet.Item] { doc.masterAt(master)!.setAt(set)!.items }

	func testAddDefaultLists() throws {
		XCTAssertEqual(try doc.addControlList(master: master), "Default Control Names")
		XCTAssertEqual(try doc.addControlList(master: master), "Default Control Names 2")
		XCTAssertEqual(doc.controlListNames(master: master), ["Default Control Names", "Default Control Names 2"])
		let rows = doc.controlRows(list: "Default Control Names", master: master)
		XCTAssertEqual(rows.count, standardControlNames.count)
		XCTAssertEqual(rows.first, ControlRow(number: "1", name: "Modulation", type: "7bit"))
		// Las listas nuevas van detrás de las PatchNameList.
		guard case .controlNameList = doc.masterAt(master)!.items.last! else { return XCTFail("orden") }
	}

	func testChannelSetUsesList() throws {
		let name = try doc.addControlList(master: master)
		try doc.setControlList(name, forChannelSet: todos, master: master)
		let items = setItems(todos)
		guard case .availableForChannels = items[0], case .usesControlNameList(name) = items[1], case .patchBank = items[2]
		else { return XCTFail("\(items)") }
		XCTAssertEqual(doc.channelSetsUsing(controlList: name, master: master), [todos])
		let other = try doc.addControlList(master: master)
		try doc.setControlList(other, forChannelSet: todos, master: master)
		XCTAssertEqual(doc.channelSetsUsing(controlList: name, master: master), [])
		XCTAssertEqual(doc.channelSetsUsing(controlList: other, master: master), [todos])
		try doc.setControlList(nil, forChannelSet: todos, master: master)
		XCTAssertEqual(doc.channelSetsUsing(controlList: other, master: master), [])
	}

	func testRenameAndDeleteFollowUses() throws {
		let name = try doc.addControlList(master: master)
		try doc.setControlList(name, forChannelSet: todos, master: master)
		try doc.setControlList(name, forChannelSet: drums, master: master)
		try doc.renameControlList(name, to: " Synth ", master: master)
		XCTAssertEqual(doc.controlListNames(master: master), ["Synth"])
		XCTAssertEqual(doc.channelSetsUsing(controlList: "Synth", master: master), [todos, drums])
		let again = try doc.addControlList(master: master)
		XCTAssertThrowsError(try doc.renameControlList(again, to: "Synth", master: master)) {
			XCTAssertEqual($0 as? ControlEditError, .duplicateList("Synth"))
		}
		try doc.deleteControlList("Synth", master: master)
		XCTAssertEqual(doc.controlListNames(master: master), [again])
		XCTAssertFalse(setItems(todos).contains { if case .usesControlNameList = $0 { return true }; return false })
	}

	func testEditControls() throws {
		let name = try doc.addControlList(master: master)
		let i = try doc.addControl(list: name, master: master)
		var rows = doc.controlRows(list: name, master: master)
		XCTAssertEqual(rows[i], ControlRow(number: "96", name: "New Control", type: "7bit"))
		XCTAssertThrowsError(try doc.setControlNumber(list: name, at: i, to: "7", master: master)) {
			XCTAssertEqual($0 as? ControlEditError, .duplicateNumber(7))
		}
		XCTAssertThrowsError(try doc.setControlNumber(list: name, at: i, to: "128", master: master)) {
			XCTAssertEqual($0 as? ControlEditError, .invalidNumber("128"))
		}
		// Al cambiar el número, la lista se reordena: el 85 va entre el 84 y el 91.
		let j = try doc.setControlNumber(list: name, at: i, to: " 85 ", master: master)
		try doc.renameControl(list: name, at: j, to: "Mix", master: master)
		XCTAssertThrowsError(try doc.renameControl(list: name, at: j, to: " ", master: master))
		rows = doc.controlRows(list: name, master: master)
		XCTAssertEqual(rows[j], ControlRow(number: "85", name: "Mix", type: "7bit"))
		XCTAssertEqual(rows[j - 1].number, "84")
		XCTAssertEqual(rows[j + 1].number, "91")
		XCTAssertEqual(rows.map { Int($0.number)! }, rows.map { Int($0.number)! }.sorted())
		try doc.deleteControls(list: name, at: IndexSet(integersIn: 0..<j), master: master)
		XCTAssertEqual(doc.controlRows(list: name, master: master).first, ControlRow(number: "85", name: "Mix", type: "7bit"))
		// El 85 pasa a 3 y sube al principio; + toma el número siguiente al último (97) y va al final.
		XCTAssertEqual(try doc.setControlNumber(list: name, at: 0, to: "3", master: master), 0)
		XCTAssertEqual(try doc.setControlNumber(list: name, at: 0, to: "120", master: master), 5)
		let k = try doc.addControl(list: name, master: master)
		rows = doc.controlRows(list: name, master: master)
		XCTAssertEqual(rows[k].number, "121")
		XCTAssertEqual(rows.map { Int($0.number)! }, rows.map { Int($0.number)! }.sorted())
	}

	/// Con listas, usos y controles editados, el fichero sigue valiendo contra la DTD (si están las DTD).
	func testEditedFileIsValid() throws {
		let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../..").standardized
		let fm = FileManager.default
		try XCTSkipUnless(fm.fileExists(atPath: repo.appendingPathComponent("reference/dtd/MIDIEvents10.dtd").path),
		                  "sin DTD en reference/dtd")
		let name = try doc.addControlList(master: master)
		try doc.setControlList(name, forChannelSet: todos, master: master)
		try doc.setControlList(name, forChannelSet: drums, master: master)
		try doc.addControl(list: name, master: master)

		let url = fm.temporaryDirectory.appendingPathComponent("cherrypicker-\(UUID().uuidString).midnam")
		defer { try? fm.removeItem(at: url) }
		try file.text().write(to: url, atomically: true, encoding: .utf8)
		let p = Process()
		p.executableURL = repo.appendingPathComponent("tools/validar_midnam.sh")
		p.arguments = [url.path]
		let pipe = Pipe()
		p.standardOutput = pipe
		p.standardError = pipe
		try p.run()
		let out = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
		p.waitUntilExit()
		XCTAssertEqual(p.terminationStatus, 0, out)
	}
}
