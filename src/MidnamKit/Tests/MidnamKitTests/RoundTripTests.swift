import Foundation
import XCTest
@testable import MidnamKit

/// Ficheros sintéticos (sin datos del usuario): formato de CherryPicker y de MOTU.
final class SyntheticTests: XCTestCase {
	static let cherryPicker = """
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE MIDINameDocument PUBLIC "-//MIDI Manufacturers Association//DTD MIDINameDocument 1.0//EN" "">

	<MIDINameDocument>
		<Author>CherryPicker</Author>
		<MasterDeviceNames>
			<Manufacturer>Fabricante &amp; Cía</Manufacturer>
			<Model>FX-1</Model>
			<CustomDeviceMode Name="Mode 1" >
				<ChannelNameSetAssignments>
					<ChannelNameSetAssign Channel="1" NameSet="Presets" />
				</ChannelNameSetAssignments>
			</CustomDeviceMode>
			<ChannelNameSet Name="Presets" >
				<AvailableForChannels>
					<AvailableChannel Channel="1" Available="true" />
				</AvailableForChannels>
				<UsesControlNameList Name="Controles" />
				<PatchBank Name="Halls" >
					<MIDICommands>
						<ControlChange Control="0" Value="1" />
						<ControlChange Control="32" Value="0" />
					</MIDICommands>
					<UsesPatchNameList Name="Halls" />
				</PatchBank>
				<PatchBank Name="Solo agrupaci&apos;n" >
					<UsesPatchNameList Name="Otros" />
				</PatchBank>
			</ChannelNameSet>
			<PatchNameList Name="Halls" >
				<Patch Number="  1" Name="Sala &lt;grande&gt;" ProgramChange="0" />
				<Patch Number="065" Name="Con comandos" >
					<PatchMIDICommands>
						<ControlChange Control="0" Value="0" />
						<ProgramChange Number="20" />
					</PatchMIDICommands>
				</Patch>
			</PatchNameList>
			<PatchNameList Name="Otros" >
				<Patch Number="1" Name="Uno" ProgramChange="0" />
			</PatchNameList>
			<ControlNameList Name="Controles" >
				<Control Type="7bit" Number="7" Name="Mix" />
			</ControlNameList>
		</MasterDeviceNames>
	</MIDINameDocument>

	"""

	static let motu = """
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE MIDINameDocument PUBLIC "-//MIDI Manufacturers Association//DTD MIDINameDocument 0.7//EN" "http://www.sonosphere.com/dtds/MIDINameDocument.dtd">

	<MIDINameDocument>
		<Author>Mark of the Unicorn - converted from FreeMIDI</Author>
		<MasterDeviceNames>
			<Manufacturer>Fabricante</Manufacturer>
			<Model>FX-2</Model>
			<CustomDeviceMode Name="Mode 1" >
				<ChannelNameSetAssignments>
					<ChannelNameSetAssign Channel="1" NameSet="Name Set 1" />
				</ChannelNameSetAssignments>
			</CustomDeviceMode>
			<ChannelNameSet Name="Name Set 1" >
				<AvailableForChannels>
					<AvailableChannel Channel="1" Available="true" />
				</AvailableForChannels>
				<PatchBank Name="P0 Halls" >
					<MIDICommands>
						<ControlChange Control="32" Value="0" />
					</MIDICommands>
					<PatchNameList>
						<Patch Number="0" Name="Hall's &gt; Room" ProgramChange="0" />
					</PatchNameList>
				</PatchBank>
			</ChannelNameSet>
		</MasterDeviceNames>
	</MIDINameDocument>
	"""

	func testCherryPickerIdaYVueltaIdentica() throws {
		let f = try MidnamFile(text: Self.cherryPicker)
		XCTAssertEqual(XMLWriter.write(f.xml), Self.cherryPicker)
		XCTAssertEqual(f.text(), Self.cherryPicker)
		XCTAssertEqual(f.xml.style, .cherryPicker)
		XCTAssertEqual(otherCount(f.document), 0)
	}

	func testMOTUIdaYVueltaIdentica() throws {
		let f = try MidnamFile(text: Self.motu)
		XCTAssertFalse(f.xml.style.escapeApostrophe)
		XCTAssertEqual(f.text(), Self.motu)
		XCTAssertEqual(otherCount(f.document), 0)
	}

	func testModeloTipado() throws {
		let d = try MidnamFile(text: Self.cherryPicker).document
		XCTAssertEqual(d.author, "CherryPicker")
		let m = try XCTUnwrap(d.masterDeviceNames.first)
		XCTAssertEqual(m.manufacturer, "Fabricante & Cía")
		XCTAssertEqual(m.models, ["FX-1"])
		let banks = try XCTUnwrap(m.channelNameSets.first).patchBanks
		XCTAssertEqual(banks.map(\.name), ["Halls", "Solo agrupaci'n"])
		XCTAssertEqual(banks[0].items.first, .midiCommands([.controlChange(control: "0", value: "1"),
		                                                    .controlChange(control: "32", value: "0")]))
		let patches = m.patchNameLists[0].patches
		XCTAssertEqual(patches[0].number, "  1")
		XCTAssertEqual(patches[0].name, "Sala <grande>")
		XCTAssertEqual(patches[1].programChange, nil)
		XCTAssertEqual(patches[1].items, [.patchMIDICommands([.controlChange(control: "0", value: "0"), .programChange(number: "20")])])
		XCTAssertEqual(m.controlNameLists.first?.items, [.control(Control(number: "7", name: "Mix"))])
	}

	func testElementoDesconocidoSeConserva() throws {
		let text = Self.cherryPicker.replacingOccurrences(of: "\t\t<Model>FX-1</Model>\n",
		                                                  with: "\t\t<Model>FX-1</Model>\n\t\t<Raro A=\"1\" >\n\t\t\t<B/>\n\t\t</Raro>\n")
		XCTAssertNotEqual(text, Self.cherryPicker)
		let f = try MidnamFile(text: text)
		XCTAssertEqual(otherCount(f.document), 1)
		XCTAssertEqual(f.text(), text)
	}

	func testAtributoExtraYOrdenNoCanonico() throws {
		let text = Self.cherryPicker
			.replacingOccurrences(of: "<Patch Number=\"1\" Name=\"Uno\" ProgramChange=\"0\" />",
			                      with: "<Patch Name=\"Uno\" Number=\"1\" ProgramChange=\"0\" />")
			.replacingOccurrences(of: "<PatchBank Name=\"Halls\" >", with: "<PatchBank Name=\"Halls\" Extra=\"x\" >")
		let f = try MidnamFile(text: text)
		XCTAssertEqual(f.text(), text)
	}

	func testNuevoDocumentoConEstiloCherryPicker() throws {
		let patch = Patch(number: "1", name: "A'B", programChange: "0")
		let list = PatchNameList(name: "L", items: [.patch(patch)])
		let m = MasterDeviceNames(items: [.manufacturer("F"), .model("M"), .patchNameList(list)])
		let doc = MIDINameDocument(items: [.author("CherryPicker"), .masterDeviceNames(m)])
		let text = MidnamFile(document: doc).text()
		XCTAssertTrue(text.contains("<Patch Number=\"1\" Name=\"A&apos;B\" ProgramChange=\"0\" />"))
		XCTAssertTrue(text.hasPrefix(MidnamFile.newFileProlog + "<MIDINameDocument>\n\t<Author>"))
		XCTAssertTrue(MidnamFile.newFileProlog.contains("\"http://www.midi.org/dtds/MIDINameDocument10.dtd\">\n\n"))
		XCTAssertTrue(text.hasSuffix("</MIDINameDocument>\n"))
		XCTAssertEqual(try MidnamFile(text: text).text(), text)
	}

	/// Formas de la DTD 1.0 que no aparecen en los ejemplos: controles en línea en el juego de canales,
	/// controles por preset, Control sin Type y con Values.
	func testFormasDTD10() throws {
		let text = Self.cherryPicker
			.replacingOccurrences(of: "\t\t\t<UsesControlNameList Name=\"Controles\" />\n",
			                      with: "\t\t\t<ControlNameList Name=\"Locales\" >\n\t\t\t\t<Control Number=\"1\" Name=\"Mod\" >\n\t\t\t\t\t<Values Min=\"0\" Max=\"127\" />\n\t\t\t\t</Control>\n\t\t\t</ControlNameList>\n")
			.replacingOccurrences(of: "\t\t\t<Patch Number=\"1\" Name=\"Uno\" ProgramChange=\"0\" />",
			                      with: "\t\t\t<Patch Number=\"1\" Name=\"Uno\" ProgramChange=\"0\" >\n\t\t\t\t<UsesControlNameList Name=\"Controles\" />\n\t\t\t</Patch>")
		XCTAssertNotEqual(text, Self.cherryPicker)
		let f = try MidnamFile(text: text)
		XCTAssertEqual(f.text(), text)
		XCTAssertEqual(otherCount(f.document), 0)
		let m = try XCTUnwrap(f.document.masterDeviceNames.first)
		guard case .controlNameList(let l) = m.channelNameSets[0].items[1], case .control(let c) = l.items[0] else {
			return XCTFail("ControlNameList en línea sin tipo")
		}
		XCTAssertNil(c.type)
		XCTAssertEqual(c.children.count, 1)
		XCTAssertEqual(m.patchNameLists[1].patches[0].items, [.usesControlNameList("Controles")])
	}

	func testErrores() {
		XCTAssertThrowsError(try MidnamFile(text: "<MIDIDeviceTypes></MIDIDeviceTypes>"))
		XCTAssertThrowsError(try MidnamFile(text: "<MIDINameDocument><Author>x</Autor></MIDINameDocument>"))
		XCTAssertThrowsError(try MidnamFile(text: "<MIDINameDocument>&raro;</MIDINameDocument>"))
	}
}

/// Ejemplos reales del usuario (privados, en reference/, no versionados). Se leen copias en un directorio temporal.
/// Otra carpeta: variable de entorno MIDNAM_EJEMPLOS. Si no hay ejemplos, el test se omite.
final class UserExamplesTests: XCTestCase {
	func testEjemplosIdaYVueltaIdentica() throws {
		let env = ProcessInfo.processInfo.environment["MIDNAM_EJEMPLOS"]
		let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../..").standardized
		let dir = env.map { URL(fileURLWithPath: $0) } ?? repo.appendingPathComponent("reference/midnam_usuario")
		let fm = FileManager.default
		let files = ((try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? [])
			.filter { $0.pathExtension == "midnam" }.sorted { $0.path < $1.path }
		try XCTSkipIf(files.isEmpty, "sin ejemplos en \(dir.path)")

		let tmp = fm.temporaryDirectory.appendingPathComponent("midnamkit-\(UUID().uuidString)")
		try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
		defer { try? fm.removeItem(at: tmp) }

		for src in files {
			let copy = tmp.appendingPathComponent(src.lastPathComponent)
			try fm.copyItem(at: src, to: copy)
			let original = try String(contentsOf: copy, encoding: .utf8)
			let f = try MidnamFile(text: original)
			let name = src.lastPathComponent
			XCTAssertEqual(XMLWriter.write(f.xml), original, "árbol: \(name)")
			XCTAssertEqual(f.text(), original, "modelo: \(name)")
			XCTAssertEqual(otherCount(f.document), 0, "elementos sin tipo: \(name)")
			let patches = original.components(separatedBy: "<Patch ").count - 1
			let typed = f.document.masterDeviceNames.flatMap { m in
				m.patchNameLists.flatMap(\.patches) + m.channelNameSets.flatMap(\.patchBanks).flatMap { b in
					b.items.flatMap { if case .patchNameList(let l) = $0 { return l.patches } else { return [] } }
				}
			}.count
			XCTAssertEqual(typed, patches, "presets: \(name)")
			print("EJEMPLO \(name): \(patches) presets, ida y vuelta idéntica")
		}
	}
}

/// Cuántos elementos quedaron sin tipo (en `.other`) en todo el documento.
func otherCount(_ d: MIDINameDocument) -> Int {
	var n = 0
	for item in d.items {
		switch item {
		case .other: n += 1
		case .author: break
		case .masterDeviceNames(let m):
			for mi in m.items {
				switch mi {
				case .other: n += 1
				case .customDeviceMode(let c): n += c.items.filter { if case .other = $0 { return true } else { return false } }.count
				case .channelNameSet(let s):
					for si in s.items {
						switch si {
						case .other: n += 1
						case .patchBank(let b):
							for bi in b.items {
								switch bi {
								case .other: n += 1
								case .midiCommands(let l): n += l.filter { if case .other = $0 { return true } else { return false } }.count
								case .patchNameList(let l): n += otherCount(l)
								case .usesPatchNameList: break
								}
							}
						case .controlNameList(let l): n += l.items.filter { if case .other = $0 { return true } else { return false } }.count
						default: break
						}
					}
				case .patchNameList(let l): n += otherCount(l)
				case .controlNameList(let l): n += l.items.filter { if case .other = $0 { return true } else { return false } }.count
				default: break
				}
			}
		}
	}
	return n
}

func otherCount(_ l: PatchNameList) -> Int {
	l.items.reduce(0) { n, i in
		switch i {
		case .other: return n + 1
		case .patch(let p):
			return n + p.items.reduce(0) { k, pi in
				switch pi {
				case .other: return k + 1
				case .patchMIDICommands(let c): return k + c.filter { if case .other = $0 { return true } else { return false } }.count
				case .usesNoteNameList, .usesControlNameList: return k
				}
			}
		}
	}
}
