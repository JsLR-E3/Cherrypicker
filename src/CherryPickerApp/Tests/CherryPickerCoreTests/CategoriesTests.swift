import Foundation
import XCTest
import MidnamKit
@testable import CherryPickerCore

/// Pestaña Categories (T-025): juegos de nombres de banco y «Add To Banks».
final class CategoriesTests: XCTestCase {
	func testStandardSetsComeFirstAndUserNamesCannotHideThem() {
		let lib = CategoryLibrary(user: [CategorySet(name: "GM Categories", bankNames: ["X"]),
		                                 CategorySet(name: "Mías", bankNames: ["Pads"], isStandard: true)])
		XCTAssertEqual(lib.sets.map(\.name), ["GM Categories", "EMU Categories", "Mías"])
		XCTAssertEqual(lib.sets[0].bankNames.count, 16)
		XCTAssertEqual(lib.sets[1].bankNames.count, 26)
		XCTAssertEqual(lib.userSets, [CategorySet(name: "Mías", bankNames: ["Pads"])])
	}

	func testStandardSetsAreReadOnly() {
		var lib = CategoryLibrary()
		XCTAssertThrowsError(try lib.removeCategories(at: [0])) {
			XCTAssertEqual($0 as? CategoryEditError, .standard("GM Categories"))
		}
		XCTAssertThrowsError(try lib.renameCategory(at: 1, to: "E")) {
			XCTAssertEqual($0 as? CategoryEditError, .standard("EMU Categories"))
		}
		XCTAssertThrowsError(try lib.addBankName("Otro", toCategory: 0))
		XCTAssertThrowsError(try lib.removeBankNames(at: [0], fromCategory: 0))
		XCTAssertThrowsError(try lib.renameBankName(at: 0, inCategory: 0, to: "Pianos"))
		XCTAssertEqual(lib, CategoryLibrary())
	}

	func testDuplicateMakesEditableCopy() throws {
		var lib = CategoryLibrary()
		let i = lib.duplicateCategory(at: 0)
		XCTAssertEqual(lib.sets[i].name, "GM Categories copy")
		XCTAssertFalse(lib.sets[i].isStandard)
		let j = lib.duplicateCategory(at: 0)
		XCTAssertEqual(lib.sets[j].name, "GM Categories copy 2")
		try lib.renameBankName(at: 0, inCategory: i, to: "Pianos")
		XCTAssertEqual(lib.sets[i].bankNames.first, "Pianos")
		XCTAssertEqual(lib.sets[0].bankNames.first, "Piano")
		try lib.removeCategories(at: [i, i + 1])
		XCTAssertEqual(lib.sets.count, 2)
	}

	func testUserCategoryEditing() throws {
		var lib = CategoryLibrary()
		let i = try lib.addCategory(named: " Mis bancos ")
		XCTAssertEqual(lib.sets[i].name, "Mis bancos")
		XCTAssertThrowsError(try lib.addCategory(named: "Mis bancos")) {
			XCTAssertEqual($0 as? CategoryEditError, .duplicateCategory("Mis bancos"))
		}
		XCTAssertThrowsError(try lib.addCategory(named: "  ")) { XCTAssertEqual($0 as? CategoryEditError, .emptyName) }
		try lib.addBankName(lib.freeBankName("New Bank", inCategory: i), toCategory: i)
		try lib.addBankName(lib.freeBankName("New Bank", inCategory: i), toCategory: i)
		XCTAssertEqual(lib.sets[i].bankNames, ["New Bank", "New Bank 2"])
		XCTAssertThrowsError(try lib.renameBankName(at: 1, inCategory: i, to: "New Bank")) {
			XCTAssertEqual($0 as? CategoryEditError, .duplicateBankName("New Bank"))
		}
		try lib.renameBankName(at: 1, inCategory: i, to: "Leads")
		try lib.removeBankNames(at: [0], fromCategory: i)
		XCTAssertEqual(lib.sets[i].bankNames, ["Leads"])
		try lib.renameCategory(at: i, to: "Favoritos")
		XCTAssertEqual(CategoryLibrary(user: lib.userSets), lib)
	}

	func testAddCustomBanksSkipsExistingNames() throws {
		var file = try MidnamFile(text: BankEditingTests.midnam)
		let todos = BankRows.rows(file.document)[0].ref
		let r = try file.document.addCustomBanks(named: ["Pads", "Uno", "Leads", " ", "Pads"],
		                                          master: todos.master, set: todos.set)
		XCTAssertEqual(r.skipped, ["Uno", "Pads"])
		XCTAssertEqual(r.added.count, 2)
		let rows = BankRows.rows(file.document)
		XCTAssertEqual(rows.map(\.name), ["Uno", "Custom", "Tres", "Pads", "Leads", "Kits"])
		for name in ["Pads", "Leads"] {
			let row = rows.first { $0.name == name }!
			XCTAssertEqual(row.kind, .empty)
			XCTAssertEqual(file.document.bank(row.ref)?.items, [.usesPatchNameList(name)])
		}
	}

	/// Con los bancos de una categoría, el fichero sigue valiendo contra la DTD (si están las DTD).
	func testFileWithCategoryBanksIsValid() throws {
		let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../..").standardized
		let fm = FileManager.default
		try XCTSkipUnless(fm.fileExists(atPath: repo.appendingPathComponent("reference/dtd/MIDIEvents10.dtd").path),
		                  "sin DTD en reference/dtd")
		var file = try MidnamFile(text: BankEditingTests.midnam)
		let kits = BankRows.rows(file.document).last!.ref
		try file.document.addCustomBanks(named: CategorySet.emu.bankNames, master: kits.master, set: kits.set)

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
