// «Copy...» de la lista de patches: hoja «Copy Fields To Clipboard» (nib CPPatchExport, CPCopySheet; manual del
// original, «Bank Export»; docs/20 §3.2; T-027). Una línea por patch con los campos marcados, en el orden elegido y
// separados por el delimitador; «Print Bank Name» pone antes una línea con el nombre del banco. El texto va al
// portapapeles (p. ej. para pegarlo en Logic) y, con «TextEdit Export», también a TextEdit (eso lo hace la app).
import Foundation

public struct PatchExport: Equatable, Sendable {
	public enum Field: String, CaseIterable, Codable, Sendable {
		case name, patchNumber, bankSelects, displayNumber

		/// Textos del nib.
		public var title: String {
			switch self {
			case .name: return "Name"
			case .patchNumber: return "Patch Number"
			case .bankSelects: return "Bank Selects"
			case .displayNumber: return "Display Number"
			}
		}
	}

	/// Popup «Delimiter» del nib.
	public enum Delimiter: String, CaseIterable, Codable, Sendable {
		case comma, tab, space

		public var title: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
		public var text: String {
			switch self {
			case .comma: return ","
			case .tab: return "\t"
			case .space: return " "
			}
		}
	}

	/// Campos marcados, en el orden de «Field Order».
	public var fields: [Field]
	public var delimiter: Delimiter
	public var quoteNames: Bool
	public var printBankName: Bool

	/// Por defecto, solo el nombre (lo que usa Logic, según el manual).
	public static let `default` = PatchExport(fields: [.name], delimiter: .tab, quoteNames: false, printBankName: false)

	public init(fields: [Field], delimiter: Delimiter, quoteNames: Bool, printBankName: Bool) {
		self.fields = fields
		self.delimiter = delimiter
		self.quoteNames = quoteNames
		self.printBankName = printBankName
	}

	/// Texto que se copia: una línea por patch (y antes la del banco, si se pide), terminada en salto de línea.
	/// «Patch Number» es el Program Change; «Display Number», el Ascii; «Bank Selects», CC0 y CC32 efectivos
	/// («-» si no se usan) separados por el delimitador.
	public func text(bankName: String, patches: [PatchRow]) -> String {
		let d = delimiter.text
		func quoted(_ s: String) -> String { quoteNames ? "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\"" : s }
		var lines: [String] = printBankName ? [quoted(bankName)] : []
		for p in patches {
			lines.append(fields.map { f -> String in
				switch f {
				case .name: return quoted(p.name)
				case .patchNumber: return p.program
				case .bankSelects: return p.bankSelect0 + d + p.bankSelect32
				case .displayNumber: return p.ascii
				}
			}.joined(separator: d))
		}
		return lines.map { $0 + "\n" }.joined()
	}
}
