// Destino MIDI virtual «CP Monitor»: anota los bytes recibidos (prueba de la audición sin módulo).
import CoreMIDI
import Foundation
setvbuf(stdout, nil, _IOLBF, 0)
var client = MIDIClientRef(), dest = MIDIEndpointRef()
MIDIClientCreateWithBlock("CP Monitor" as CFString, &client, nil)
let st = MIDIDestinationCreateWithProtocol(client, "CP Monitor" as CFString, ._1_0, &dest) { list, _ in
	for p in list.unsafeSequence() {
		let words = withUnsafeBytes(of: p.pointee.words) { Array($0.bindMemory(to: UInt32.self).prefix(Int(p.pointee.wordCount))) }
		for w in words {
			let b = [UInt8((w >> 16) & 0xFF), UInt8((w >> 8) & 0xFF), UInt8(w & 0xFF)]
			let n = (b[0] & 0xF0) == 0xC0 ? 2 : 3
			print(Date().timeIntervalSince1970, b.prefix(n).map { String(format: "%02X", $0) }.joined(separator: " "), String(format: "(UMP %08X)", w))
		}
	}
}
print("creado", st)
RunLoop.main.run()
