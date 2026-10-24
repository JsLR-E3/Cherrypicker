import XCTest
@testable import CherryPickerCore

/// «Copy...» de la lista de patches (T-027).
final class PatchExportTests: XCTestCase {
	let rows = [
		PatchRow(index: 0, bankSelect0: "1", bankSelect32: "5", program: "0", name: "Grand \"A\"", ascii: "001"),
		PatchRow(index: 1, bankSelect0: "-", bankSelect32: "-", program: "7", name: "Pad", ascii: "A12"),
	]

	func testDefaultIsNamesOnly() {
		XCTAssertEqual(PatchExport.default.text(bankName: "Uno", patches: rows), "Grand \"A\"\nPad\n")
	}

	func testFieldsInOrderWithDelimiterQuotesAndBank() {
		let e = PatchExport(fields: [.displayNumber, .name, .bankSelects, .patchNumber], delimiter: .comma,
		                    quoteNames: true, printBankName: true)
		XCTAssertEqual(e.text(bankName: "Uno", patches: rows),
		               "\"Uno\"\n001,\"Grand \"\"A\"\"\",1,5,0\nA12,\"Pad\",-,-,7\n")
	}

	func testTabAndSpace() {
		var e = PatchExport(fields: [.patchNumber, .name], delimiter: .tab, quoteNames: false, printBankName: false)
		XCTAssertEqual(e.text(bankName: "Uno", patches: [rows[1]]), "7\tPad\n")
		e.delimiter = .space
		XCTAssertEqual(e.text(bankName: "Uno", patches: [rows[1]]), "7 Pad\n")
		XCTAssertEqual(PatchExport.Delimiter.allCases.map(\.title), ["Comma", "Tab", "Space"])
	}

	func testNoPatches() {
		XCTAssertEqual(PatchExport.default.text(bankName: "Uno", patches: []), "")
	}
}
