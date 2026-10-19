// Escritor con el formato de CherryPicker 3.0 (CPXMLStrings.plist, EXP-001):
// sangría con tabuladores, `<Elem A="v" >` al abrir con atributos, `<Elem A="v" />` vacío, texto en la misma línea.

public enum XMLWriter {
	public static func write(_ doc: XMLDocumentFile) -> String {
		var out = doc.prolog
		write(doc.root, depth: 0, style: doc.style, into: &out)
		out += doc.epilog
		return out
	}

	static func write(_ e: XMLElement, depth: Int, style: XMLWriteStyle, into out: inout String) {
		let indent = String(repeating: "\t", count: depth)
		var open = "<" + e.name
		for a in e.attributes {
			open += " \(a.name)=\"\(escape(a.value, attribute: true, style: style))\""
		}
		let hasAttributes = !e.attributes.isEmpty
		if e.children.isEmpty {
			out += indent + open + (hasAttributes ? " />" : "/>")
		} else if e.children.allSatisfy({ if case .text = $0 { return true } else { return false } }) {
			out += indent + open + (hasAttributes ? " >" : ">")
			out += escape(e.text, attribute: false, style: style) + "</\(e.name)>"
		} else {
			out += indent + open + (hasAttributes ? " >" : ">")
			for child in e.children {
				out += "\n"
				switch child {
				case .element(let c):
					write(c, depth: depth + 1, style: style, into: &out)
				case .text(let t):
					out += indent + "\t" + escape(t, attribute: false, style: style)
				case .comment(let c):
					out += indent + "\t<!--\(c)-->"
				}
			}
			out += "\n" + indent + "</\(e.name)>"
		}
	}

	static func escape(_ s: String, attribute: Bool, style: XMLWriteStyle) -> String {
		guard s.contains(where: { "&<>\"'".contains($0) }) else { return s }
		var r = ""
		r.reserveCapacity(s.utf8.count + 8)
		for ch in s {
			switch ch {
			case "&": r += "&amp;"
			case "<": r += "&lt;"
			case ">": r += "&gt;"
			case "\"" where attribute || style.escapeQuoteInText: r += "&quot;"
			case "'" where style.escapeApostrophe: r += "&apos;"
			default: r.append(ch)
			}
		}
		return r
	}
}
