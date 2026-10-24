// OCR de un PDF escaneado con Vision de macOS (sin instalar nada); ordena las líneas de arriba abajo.
// Uso: swift tools/ocr_pdf.swift entrada.pdf salida.txt
import PDFKit; import Vision; import AppKit
let a = CommandLine.arguments
let d = PDFDocument(url: URL(fileURLWithPath: a[1]))!
var out = ""
for i in 0..<d.pageCount {
  let p = d.page(at:i)!; let r = p.bounds(for:.mediaBox)
  let img = p.thumbnail(of: NSSize(width:r.width*3,height:r.height*3), for:.mediaBox)
  var rect = CGRect(origin:.zero,size:img.size)
  guard let cg = img.cgImage(forProposedRect:&rect, context:nil, hints:nil) else { continue }
  let req = VNRecognizeTextRequest(); req.recognitionLevel = .accurate; req.usesLanguageCorrection = false
  try? VNImageRequestHandler(cgImage: cg).perform([req])
  let obs = (req.results ?? []).sorted { a,b in abs(a.boundingBox.midY-b.boundingBox.midY) > 0.008 ? a.boundingBox.midY > b.boundingBox.midY : a.boundingBox.minX < b.boundingBox.minX }
  out += "\n=== PAGE \(i+1) ===\n" + obs.compactMap{ $0.topCandidates(1).first?.string }.joined(separator:"\n")
}
try! out.write(toFile:a[2], atomically:true, encoding:.utf8)
