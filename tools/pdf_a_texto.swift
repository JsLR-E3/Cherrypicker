// Pasa un PDF a texto, página a página (PDFKit, sin instalar nada).
// Uso: swift tools/pdf_a_texto.swift entrada.pdf salida.txt
import PDFKit
let a = CommandLine.arguments
guard let d = PDFDocument(url: URL(fileURLWithPath: a[1])) else { exit(1) }
var out = ""
for i in 0..<d.pageCount { out += "\n=== PAGE \(i+1) ===\n" + (d.page(at: i)?.string ?? "") }
try! out.write(toFile: a[2], atomically: true, encoding: .utf8)
