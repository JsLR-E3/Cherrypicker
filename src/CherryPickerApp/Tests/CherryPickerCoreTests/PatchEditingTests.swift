import Foundation
import XCTest
import MidnamKit
@testable import CherryPickerCore

/// Lista de patches (T-018) sobre el fichero sintético de BankEditingTests: «Uno» (banco 1/5, forma corta),
/// «Custom» (sin bank select de banco; C con 2/0 propios, D en forma corta), «Tres» y «Kits» (lista compartida).
final class PatchEditingTests: XCTestCase {
	var file: MidnamFile!
	var doc: MIDINameDocument { get { file.document } set { file.document = newValue } }

	override func setUp() {
		file = try! MidnamFile(text: BankEditingTests.midnam)
	}

	func ref(_ name: String) -> BankRef { BankRows.rows(doc).first { $0.name == name }!.ref }
	func rows(_ bank: String) -> [PatchRow] { doc.patchRows(ref(bank)) }
	func cols(_ bank: String) -> [String] {
		rows(bank).map { "\($0.bankSelect0)/\($0.bankSelect32) \($0.program) \($0.name) \($0.ascii)" }
	}
	func patches(_ bank: String) -> [Patch] { doc.patchList(ref(bank))!.patches }

	func testRows() {
		XCTAssertEqual(cols("Uno"), ["1/5 0 A 1", "1/5 1 B 2"])
		XCTAssertEqual(cols("Custom"), ["2/0 7 C 1", "-/- 3 D 2"])
	}

	func testDelimiters() {
		XCTAssertEqual(PatchDelimiter.endOfLine.names(in: "uno\r\n dos \n\ntres\n"), ["uno", "dos", "tres"])
		XCTAssertEqual(PatchDelimiter.comma.names(in: "uno, dos,,tres"), ["uno", "dos", "tres"])
		XCTAssertEqual(PatchDelimiter.tab.names(in: "uno\tdos\t"), ["uno", "dos"])
		XCTAssertEqual(PatchDelimiter.quote.names(in: "\"uno\" \"dos, tres\" \"sin cerrar"), ["uno", "dos, tres"])
		XCTAssertEqual(PatchDelimiter.allCases.map(\.title), ["End of line", "Comma", "Quote", "Tab"])
	}

	func testNextAscii() {
		XCTAssertEqual(nextAscii("001"), "002")
		XCTAssertEqual(nextAscii("009", by: 2), "011")
		XCTAssertEqual(nextAscii("A99"), "A100")
		XCTAssertEqual(nextAscii("  7", by: 3), "  10")
		XCTAssertEqual(nextAscii("Kit"), "Kit")
	}

	/// Valores por defecto de la hoja (EXP-012): Start At 0, Start Ascii 001; `Number` = Ascii, PC = Start At + i.
	func testAddPastedNamesBeforeSelection() throws {
		let r = try doc.addPatches(ref("Uno"), names: PatchDelimiter.endOfLine.names(in: "uno\ndos"), startAt: 0,
		                           startAscii: "001", useBankSelects: true, before: 1)
		XCTAssertEqual(r, 1..<3)
		XCTAssertEqual(cols("Uno"), ["1/5 0 A 1", "1/5 0 uno 001", "1/5 1 dos 002", "1/5 1 B 2"])
		XCTAssertEqual(patches("Uno")[1], Patch(number: "001", name: "uno", programChange: "0"), "forma corta")
	}

	/// Regla P9: sin la casilla, en un banco con bank select, el patch queda en «-» (solo Program Change).
	func testAddWithoutBankSelectsInBankWithSelect() throws {
		try doc.addPatches(ref("Uno"), names: ["", ""], startAt: 10, startAscii: "011", useBankSelects: false)
		XCTAssertEqual(cols("Uno").suffix(2), ["-/- 10  011", "-/- 11  012"])
		XCTAssertEqual(patches("Uno")[2].items, [.patchMIDICommands([.programChange(number: "10")])])
		XCTAssertNil(patches("Uno")[2].programChange)
	}

	/// En un banco sin bank select la casilla no cambia nada (EXP-012): forma corta.
	func testAddWithoutBankSelectsInBankWithoutSelect() throws {
		try doc.addPatches(ref("Custom"), names: ["x"], startAt: 0, startAscii: "001", useBankSelects: false)
		XCTAssertEqual(patches("Custom").last, Patch(number: "001", name: "x", programChange: "0"))
	}

	func testAddRejectsOutOfRange() {
		XCTAssertThrowsError(try doc.addPatches(ref("Uno"), names: ["a", "b"], startAt: 127, startAscii: "1",
		                                        useBankSelects: true)) {
			XCTAssertEqual($0 as? PatchEditError, .programOutOfRange(128))
		}
		XCTAssertThrowsError(try doc.addPatches(ref("Uno"), names: ["a"], startAt: 0, startAscii: " ", useBankSelects: true))
		XCTAssertEqual(patches("Uno").count, 2)
	}

	func testEditCells() throws {
		try doc.renamePatch(ref("Custom"), at: 0, to: "Nuevo")
		try doc.setPatchAscii(ref("Custom"), at: 0, to: " A01 ")
		try doc.setPatchProgram(ref("Custom"), at: 0, to: "9")
		try doc.setPatchProgram(ref("Custom"), at: 1, to: "4")
		XCTAssertEqual(cols("Custom"), ["2/0 9 Nuevo A01", "-/- 4 D 2"])
		XCTAssertEqual(patches("Custom")[1], Patch(number: "2", name: "D", programChange: "4"))
		XCTAssertThrowsError(try doc.setPatchProgram(ref("Custom"), at: 0, to: "128"))
		XCTAssertThrowsError(try doc.setPatchAscii(ref("Custom"), at: 0, to: ""))
		XCTAssertThrowsError(try doc.renamePatch(ref("Custom"), at: 5, to: "x")) {
			XCTAssertEqual($0 as? PatchEditError, .notFound)
		}
	}

	func testPatchBankSelect() throws {
		// Distinto del banco: propios, con el Program Change dentro.
		try doc.setPatchBankSelect(ref("Uno"), at: 0, bs0: "3", bs32: "0")
		XCTAssertEqual(patches("Uno")[0].items, [.patchMIDICommands([
			.controlChange(control: "0", value: "3"), .controlChange(control: "32", value: "0"), .programChange(number: "0")])])
		XCTAssertEqual(BankRows.rows(doc)[0].kind, .mixed)
		// «-» en un banco con bank select: solo Program Change.
		try doc.setPatchBankSelect(ref("Uno"), at: 0, bs0: "-", bs32: "-")
		XCTAssertEqual(patches("Uno")[0].items, [.patchMIDICommands([.programChange(number: "0")])])
		// Igual que el banco: vuelve a la forma corta.
		try doc.setPatchBankSelect(ref("Uno"), at: 0, bs0: "1", bs32: "5")
		XCTAssertEqual(patches("Uno")[0], Patch(number: "1", name: "A", programChange: "0"))
		XCTAssertEqual(BankRows.rows(doc)[0].kind, .normal)
		// Banco sin bank select: «-» es la forma corta.
		try doc.setPatchBankSelect(ref("Custom"), at: 0, bs0: "-", bs32: "-")
		XCTAssertEqual(patches("Custom")[0], Patch(number: "1", name: "C", programChange: "7"))
		XCTAssertThrowsError(try doc.setPatchBankSelect(ref("Custom"), at: 0, bs0: "200", bs32: "-"))
	}

	func testDeleteAndRenumber() throws {
		try doc.addPatches(ref("Uno"), names: ["c", "d"], startAt: 50, startAscii: "x", useBankSelects: true)
		try doc.deletePatches(ref("Uno"), at: [1])
		XCTAssertEqual(rows("Uno").map(\.name), ["A", "c", "d"])
		try doc.renumberPatches(ref("Uno"), indices: [1, 2], midiStart: 5, displayStart: "005")
		XCTAssertEqual(cols("Uno"), ["1/5 0 A 1", "1/5 5 c 005", "1/5 6 d 006"])
		try doc.renumberPatches(ref("Uno"), midiStart: 0, displayStart: "1")
		XCTAssertEqual(rows("Uno").map { "\($0.program) \($0.ascii)" }, ["0 1", "1 2", "2 3"])
		XCTAssertThrowsError(try doc.renumberPatches(ref("Uno"), midiStart: 126, displayStart: "1")) {
			XCTAssertEqual($0 as? PatchEditError, .programOutOfRange(128))
		}
		XCTAssertThrowsError(try doc.deletePatches(ref("Uno"), at: [3]))
	}

	func testRenumberKeepsOwnBankSelect() throws {
		try doc.renumberPatches(ref("Custom"), midiStart: 20, displayStart: "001")
		XCTAssertEqual(cols("Custom"), ["2/0 20 C 001", "-/- 21 D 002"])
	}

	func testMoveWithinList() throws {
		try doc.addPatches(ref("Uno"), names: ["c", "d"], startAt: 2, startAscii: "3", useBankSelects: true)
		XCTAssertEqual(try doc.movePatches(ref("Uno"), at: [0, 2], before: 4), 2..<4)
		XCTAssertEqual(rows("Uno").map(\.name), ["B", "d", "A", "c"])
		XCTAssertEqual(try doc.movePatches(ref("Uno"), at: [3], before: 0), 0..<1)
		XCTAssertEqual(rows("Uno").map(\.name), ["c", "B", "d", "A"])
	}

	/// Entre listas, cada patch sigue sonando con el mismo bank select.
	func testCopyAndMoveBetweenLists() throws {
		// Uno (1/5, forma corta) → Custom (sin bank select): pasa a llevar 1/5 propios.
		try doc.copyPatches(from: ref("Uno"), at: [0], to: ref("Custom"), before: 0)
		XCTAssertEqual(cols("Custom"), ["1/5 0 A 1", "2/0 7 C 1", "-/- 3 D 2"])
		XCTAssertEqual(rows("Uno").count, 2, "copiar no borra")
		// Custom → Uno, moviendo: D («-/-» en un banco sin bank select) queda en «-» explícito; el 1/5 vuelve a forma corta.
		try doc.copyPatches(from: ref("Custom"), at: [0, 2], to: ref("Uno"), move: true)
		XCTAssertEqual(cols("Uno"), ["1/5 0 A 1", "1/5 1 B 2", "1/5 0 A 1", "-/- 3 D 2"])
		XCTAssertEqual(patches("Uno")[2], Patch(number: "1", name: "A", programChange: "0"))
		XCTAssertEqual(patches("Uno")[3].items, [.patchMIDICommands([.programChange(number: "3")])])
		XCTAssertEqual(rows("Custom").map(\.name), ["C"])
	}

	/// «Tres» y «Kits» comparten lista: mover entre ellos es reordenar, y los cambios se ven en los dos.
	func testSharedList() throws {
		try doc.addPatches(ref("Tres"), names: ["F"], startAt: 1, startAscii: "2", useBankSelects: true)
		XCTAssertEqual(rows("Kits").map(\.name), ["E", "F"])
		try doc.copyPatches(from: ref("Tres"), at: [1], to: ref("Kits"), before: 0, move: true)
		XCTAssertEqual(rows("Tres").map(\.name), ["F", "E"])
	}

	/// Tras las operaciones, el fichero se escribe y sigue valiendo contra la DTD (si están las DTD).
	func testEditedFileIsValid() throws {
		try doc.addPatches(ref("Uno"), names: ["uno"], startAt: 0, startAscii: "001", useBankSelects: false, before: 0)
		try doc.setPatchBankSelect(ref("Custom"), at: 1, bs0: "4", bs32: "-")
		try doc.copyPatches(from: ref("Uno"), at: [1], to: ref("Custom"), move: true)
		try doc.deletePatches(ref("Custom"), at: [0])
		try doc.renumberPatches(ref("Custom"), midiStart: 0, displayStart: "001")
		let text = file.text()
		XCTAssertEqual(try MidnamFile(text: text).document, doc, "ida y vuelta")
		let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../..").standardized
		try XCTSkipUnless(FileManager.default.fileExists(atPath: repo.appendingPathComponent("reference/dtd/MIDIEvents10.dtd").path),
		                  "sin DTD en reference/dtd")
		let url = FileManager.default.temporaryDirectory.appendingPathComponent("patchediting-\(UUID().uuidString).midnam")
		try text.write(to: url, atomically: true, encoding: .utf8)
		defer { try? FileManager.default.removeItem(at: url) }
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
