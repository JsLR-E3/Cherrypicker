import Foundation
import XCTest
import MidnamKit
@testable import CherryPickerCore

/// Arrastrar bancos y patches entre documentos (T-026): se copia, el origen no cambia.
final class TransferTests: XCTestCase {
	var source: MIDINameDocument!
	var target: MIDINameDocument!

	override func setUp() {
		source = try! MidnamFile(text: BankEditingTests.midnam).document
		target = source
	}

	func ref(_ doc: MIDINameDocument, _ name: String) -> BankRef { BankRows.rows(doc).first { $0.name == name }!.ref }
	func rows(_ doc: MIDINameDocument) -> [BankRow] { BankRows.rows(doc) }

	func testCopyPatchesKeepTheirBankSelect() throws {
		let original = source!
		let r = try target.copyPatches([(ref(source, "Uno"), 1), (ref(source, "Custom"), 0)], from: source,
		                               to: ref(target, "Custom"), before: 0)
		XCTAssertEqual(r, 0..<2)
		let got = target.patchRows(ref(target, "Custom"))
		XCTAssertEqual(got.map(\.name), ["B", "C", "C", "D"])
		XCTAssertEqual(got.prefix(2).map { "\($0.bankSelect0)/\($0.bankSelect32) \($0.program)" }, ["1/5 1", "2/0 7"])
		XCTAssertEqual(source, original)
	}

	func testCopyBanksRenamesAndGetsOwnLists() throws {
		let original = source!
		let drums = ref(target, "Kits")
		let r = try target.copyBanks([ref(source, "Uno"), ref(source, "Tres")], from: source,
		                             master: drums.master, set: drums.set, before: 0)
		XCTAssertEqual(r.missingLists, [])
		XCTAssertEqual(rows(target).map(\.name), ["Uno", "Custom", "Tres", "Uno 2", "Tres 2", "Kits"])
		let uno2 = rows(target)[3]
		XCTAssertEqual("\(uno2.bankSelect0)/\(uno2.bankSelect32)", "1/5")
		XCTAssertEqual(target.patchRows(uno2.ref).map(\.name), ["A", "B"])
		XCTAssertEqual(target.bank(uno2.ref)?.usedListName, "Uno 2")
		// La lista compartida del origen pasa a ser propia de la copia; la original sigue usada por Kits.
		XCTAssertEqual(target.bank(rows(target)[4].ref)?.usedListName, "Tres 2")
		XCTAssertEqual(target.bank(ref(target, "Kits"))?.usedListName, "Compartida")
		XCTAssertEqual(r.added, [rows(target)[3].ref, rows(target)[4].ref])
		XCTAssertEqual(source, original)
	}

	/// P21: banco nuevo con patches de otro documento, colocado en medio de su Channel Set.
	func testAddBankWithPatchesFromOtherDocument() throws {
		let original = source!
		let uno = ref(target, "Uno")
		let name = target.freeBankName("Uno", master: uno.master)
		XCTAssertEqual(name, "Uno 2")
		let r = try target.addBank(name: name, bs0: "-", bs32: "-", master: uno.master, set: uno.set,
		                           withPatches: [(ref(source, "Uno"), 1), (ref(source, "Custom"), 0)], from: source,
		                           before: 1)
		XCTAssertEqual(rows(target).map(\.name), ["Uno", "Uno 2", "Custom", "Tres", "Kits"])
		XCTAssertEqual(r, rows(target)[1].ref)
		let got = target.patchRows(r)
		XCTAssertEqual(got.map { "\($0.bankSelect0)/\($0.bankSelect32) \($0.program) \($0.name)" },
		               ["1/5 1 B", "2/0 7 C"])
		XCTAssertEqual(target.bank(r)?.usedListName, "Uno 2")
		XCTAssertEqual(source, original)
	}

	/// P21: sin posición, al final de su Channel Set; con nombre ocupado no se crea.
	func testAddBankWithPatchesAtEndAndDuplicateName() throws {
		let kits = ref(target, "Kits")
		try target.addBank(name: "Nuevo", bs0: "-", bs32: "-", master: kits.master, set: kits.set,
		                   withPatches: [(ref(source, "Tres"), 0)], from: source)
		XCTAssertEqual(rows(target).map(\.name), ["Uno", "Custom", "Tres", "Kits", "Nuevo"])
		XCTAssertThrowsError(try target.addBank(name: "Kits", bs0: "-", bs32: "-", master: kits.master, set: kits.set,
		                                        withPatches: [], from: source))
	}

	func testCopyBanksAtEndAndMissingLists() throws {
		let uno = ref(source, "Uno")
		try source.modifyMaster(uno.master) { m in
			try m.modifyPatches(of: uno) { $0.items.append(.usesNoteNameList("Mapa")) }
		}
		let todos = ref(target, "Uno")
		let r = try target.copyBanks([uno], from: source, master: todos.master, set: todos.set)
		XCTAssertEqual(r.missingLists, ["Mapa"])
		XCTAssertEqual(rows(target).map(\.name), ["Uno", "Custom", "Tres", "Uno 2", "Kits"])
	}

	/// Tras copiar bancos y patches de otro documento, el destino sigue valiendo contra la DTD (si están las DTD).
	func testTargetStaysValid() throws {
		let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../..").standardized
		let fm = FileManager.default
		try XCTSkipUnless(fm.fileExists(atPath: repo.appendingPathComponent("reference/dtd/MIDIEvents10.dtd").path),
		                  "sin DTD en reference/dtd")
		var file = try MidnamFile(text: BankEditingTests.midnam)
		let kits = ref(file.document, "Kits")
		try file.document.copyBanks([ref(source, "Uno"), ref(source, "Custom"), ref(source, "Tres")], from: source,
		                            master: kits.master, set: kits.set, before: 1)
		try file.document.copyPatches([(ref(source, "Custom"), 0)], from: source, to: ref(file.document, "Kits"))

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
