// Ayuda de la app (Help ▸ Midnamer Help, T-036): la parte del README.md entre `<!-- help:start -->` y
// `<!-- help:end -->`, partida en bloques. Solo lo que usa esa guía: títulos #, ## y ###, párrafos y listas «- » o
// «1. » con líneas de continuación sangradas. El formato dentro de la línea (**negrita**, `código`) lo hace la app.
import Foundation

public enum HelpBlock: Equatable {
	case heading(level: Int, text: String)
	case paragraph(String)
	/// Elemento de lista con su marca («•» o «1.»).
	case item(marker: String, text: String)
}

public enum HelpText {
	/// Lo que hay entre las marcas; sin ellas, todo el texto.
	public static func section(of markdown: String) -> String {
		guard let start = markdown.range(of: "<!-- help:start -->"),
		      let end = markdown.range(of: "<!-- help:end -->", range: start.upperBound..<markdown.endIndex)
		else { return markdown }
		return String(markdown[start.upperBound..<end.lowerBound])
	}

	public static func blocks(_ markdown: String) -> [HelpBlock] {
		var blocks: [HelpBlock] = []
		var current: HelpBlock?
		func flush() {
			if let current { blocks.append(current) }
			current = nil
		}
		for raw in markdown.components(separatedBy: .newlines) {
			let line = raw.trimmingCharacters(in: .whitespaces)
			if line.isEmpty { flush(); continue }
			if let hashes = line.firstIndex(where: { $0 != "#" }), hashes != line.startIndex,
			   line[hashes] == " " {
				flush()
				blocks.append(.heading(level: line.distance(from: line.startIndex, to: hashes),
				                       text: String(line[hashes...]).trimmingCharacters(in: .whitespaces)))
				continue
			}
			if line.hasPrefix("- ") {
				flush()
				current = .item(marker: "•", text: String(line.dropFirst(2)))
				continue
			}
			if let dot = line.firstIndex(of: "."), dot != line.startIndex, line[..<dot].allSatisfy(\.isNumber),
			   line[line.index(after: dot)...].hasPrefix(" ") {
				flush()
				current = .item(marker: String(line[...dot]),
				                text: String(line[line.index(dot, offsetBy: 2)...]))
				continue
			}
			switch current {
			case .item(let marker, let text) where raw.hasPrefix(" "):
				current = .item(marker: marker, text: text + " " + line)
			case .paragraph(let text):
				current = .paragraph(text + " " + line)
			default:
				flush()
				current = .paragraph(line)
			}
		}
		flush()
		return blocks
	}
}
