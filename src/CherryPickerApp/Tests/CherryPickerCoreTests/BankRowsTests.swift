import XCTest
import MidnamKit
@testable import CherryPickerCore

/// Fichero sintético (sin datos del usuario).
final class BankRowsTests: XCTestCase {
	static let midnam = """
	<?xml version="1.0" encoding="UTF-8"?>
	<MIDINameDocument>
		<MasterDeviceNames>
			<Manufacturer>Prueba</Manufacturer>
			<Model>P-1</Model>
			<ChannelNameSet Name="Todos" >
				<AvailableForChannels>
					<AvailableChannel Channel="1" Available="true" />
				</AvailableForChannels>
				<PatchBank Name="Uno" >
					<MIDICommands>
						<ControlChange Control="0" Value="1" />
						<ControlChange Control="32" Value="5" />
					</MIDICommands>
					<UsesPatchNameList Name="Lista" />
				</PatchBank>
				<PatchBank Name="Agrupacion" >
					<UsesPatchNameList Name="No existe" />
				</PatchBank>
				<PatchBank Name="En linea" >
					<MIDICommands>
						<ControlChange Control="0" Value="0" />
					</MIDICommands>
					<PatchNameList>
						<Patch Number="1" Name="A" ProgramChange="0" />
					</PatchNameList>
				</PatchBank>
			</ChannelNameSet>
			<ChannelNameSet Name="Drums" >
				<AvailableForChannels>
					<AvailableChannel Channel="10" Available="true" />
				</AvailableForChannels>
				<PatchBank Name="Kits" >
					<UsesPatchNameList Name="Lista" />
				</PatchBank>
			</ChannelNameSet>
			<PatchNameList Name="Lista" >
				<Patch Number="1" Name="A" ProgramChange="0" />
				<Patch Number="2" Name="B" ProgramChange="1" />
			</PatchNameList>
		</MasterDeviceNames>
	</MIDINameDocument>
	"""

	func testRows() throws {
		let file = try XMLReader.parse(Self.midnam)
		let doc = try MIDINameDocument(element: file.root)
		XCTAssertEqual(BankRows.rows(doc), [
			BankRow(bankSelect0: "1", bankSelect32: "5", name: "Uno", patchCount: 2, channelSet: "Todos"),
			BankRow(bankSelect0: "-", bankSelect32: "-", name: "Agrupacion", patchCount: nil, channelSet: "Todos"),
			BankRow(bankSelect0: "0", bankSelect32: "-", name: "En linea", patchCount: 1, channelSet: "Todos"),
			BankRow(bankSelect0: "-", bankSelect32: "-", name: "Kits", patchCount: 2, channelSet: "Drums"),
		])
	}
}
