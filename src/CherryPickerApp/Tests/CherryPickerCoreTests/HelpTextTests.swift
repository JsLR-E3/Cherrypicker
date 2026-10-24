import Foundation
import XCTest
@testable import CherryPickerCore

final class HelpTextTests: XCTestCase {
	func testBlocks() {
		let md = """
		## Title
		Some text
		that continues.

		1. First step,
		   continued.
		2. Second.
		- A bullet
		  with more.
		Not indented.
		### Sub
		"""
		XCTAssertEqual(HelpText.blocks(md), [
			.heading(level: 2, text: "Title"),
			.paragraph("Some text that continues."),
			.item(marker: "1.", text: "First step, continued."),
			.item(marker: "2.", text: "Second."),
			.item(marker: "•", text: "A bullet with more."),
			.paragraph("Not indented."),
			.heading(level: 3, text: "Sub"),
		])
	}

	func testSection() {
		XCTAssertEqual(HelpText.section(of: "a <!-- help:start -->b<!-- help:end --> c"), "b")
		XCTAssertEqual(HelpText.section(of: "sin marcas"), "sin marcas")
	}

	/// La ayuda de la app sale del README del repositorio: tiene marcas, empieza por un título y no incluye la licencia.
	func testReadme() throws {
		let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../..").standardized
		let readme = try String(contentsOf: repo.appendingPathComponent("README.md"), encoding: .utf8)
		let section = HelpText.section(of: readme)
		XCTAssertNotEqual(section, readme)
		let blocks = HelpText.blocks(section)
		XCTAssertEqual(blocks.first, .heading(level: 2, text: "What it does"))
		XCTAssertFalse(section.contains("## License"))
		XCTAssertTrue(blocks.contains(.heading(level: 2, text: "Quick start")))
	}
}
