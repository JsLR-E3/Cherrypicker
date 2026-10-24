// Dibuja el icono de Midnamer (D-011, T-035) con Core Graphics, sin imágenes de terceros: una lista de nombres sobre
// fondo azul y un conector MIDI DIN de 5 pines. Uso: swift tools/icono/dibujar_icono.swift <carpeta.iconset>
// (tools/empaquetar_app.sh lo convierte después en .icns con iconutil).
import AppKit

func dibujar(_ ctx: CGContext, _ s: CGFloat) {
	let u = s / 1024 // todo se mide sobre 1024
	ctx.clear(CGRect(x: 0, y: 0, width: s, height: s))

	// Fondo: rectángulo redondeado de la rejilla de iconos de macOS (824 de lado, radio 185), con sombra.
	let fondo = CGRect(x: 100 * u, y: 100 * u, width: 824 * u, height: 824 * u)
	let forma = CGPath(roundedRect: fondo, cornerWidth: 185 * u, cornerHeight: 185 * u, transform: nil)
	ctx.saveGState()
	ctx.setShadow(offset: CGSize(width: 0, height: -10 * u), blur: 24 * u, color: NSColor(white: 0, alpha: 0.35).cgColor)
	ctx.addPath(forma)
	ctx.setFillColor(NSColor.black.cgColor)
	ctx.fillPath()
	ctx.restoreGState()
	ctx.saveGState()
	ctx.addPath(forma)
	ctx.clip()
	let azul = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
	                      colors: [NSColor(red: 0.18, green: 0.42, blue: 0.86, alpha: 1).cgColor,
	                               NSColor(red: 0.07, green: 0.16, blue: 0.42, alpha: 1).cgColor] as CFArray,
	                      locations: [0, 1])!
	ctx.drawLinearGradient(azul, start: CGPoint(x: 0, y: 924 * u), end: CGPoint(x: 0, y: 100 * u), options: [])

	// Hoja con la lista de nombres (arriba a la izquierda).
	let hoja = CGRect(x: 200 * u, y: 330 * u, width: 470 * u, height: 500 * u)
	ctx.saveGState()
	ctx.setShadow(offset: CGSize(width: 0, height: -8 * u), blur: 20 * u, color: NSColor(white: 0, alpha: 0.4).cgColor)
	ctx.addPath(CGPath(roundedRect: hoja, cornerWidth: 36 * u, cornerHeight: 36 * u, transform: nil))
	ctx.setFillColor(NSColor(red: 0.97, green: 0.97, blue: 0.95, alpha: 1).cgColor)
	ctx.fillPath()
	ctx.restoreGState()
	// Filas: número (corto, azul) y nombre (largo, gris); la tercera, seleccionada.
	let largos: [CGFloat] = [250, 190, 270, 160, 230]
	for (i, largo) in largos.enumerated() {
		let y = hoja.maxY - 95 * u - CGFloat(i) * 82 * u
		if i == 2 {
			ctx.setFillColor(NSColor(red: 0.18, green: 0.42, blue: 0.86, alpha: 0.18).cgColor)
			ctx.fill(CGRect(x: hoja.minX, y: y - 22 * u, width: hoja.width, height: 70 * u))
		}
		ctx.setFillColor(NSColor(red: 0.18, green: 0.42, blue: 0.86, alpha: 1).cgColor)
		ctx.addPath(CGPath(roundedRect: CGRect(x: hoja.minX + 45 * u, y: y, width: 60 * u, height: 26 * u),
		                   cornerWidth: 13 * u, cornerHeight: 13 * u, transform: nil))
		ctx.fillPath()
		ctx.setFillColor(NSColor(white: 0.45, alpha: 1).cgColor)
		ctx.addPath(CGPath(roundedRect: CGRect(x: hoja.minX + 130 * u, y: y, width: largo * u, height: 26 * u),
		                   cornerWidth: 13 * u, cornerHeight: 13 * u, transform: nil))
		ctx.fillPath()
	}

	// Conector MIDI DIN (abajo a la derecha): carcasa metálica, cara negra, 5 pines en arco y la muesca arriba.
	let c = CGPoint(x: 640 * u, y: 340 * u)
	let r = 200 * u
	ctx.saveGState()
	ctx.setShadow(offset: CGSize(width: 0, height: -10 * u), blur: 26 * u, color: NSColor(white: 0, alpha: 0.5).cgColor)
	ctx.setFillColor(NSColor(white: 0.82, alpha: 1).cgColor)
	ctx.fillEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
	ctx.restoreGState()
	let metal = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
	                       colors: [NSColor(white: 0.95, alpha: 1).cgColor, NSColor(white: 0.62, alpha: 1).cgColor] as CFArray,
	                       locations: [0, 1])!
	ctx.saveGState()
	ctx.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
	ctx.clip()
	ctx.drawLinearGradient(metal, start: CGPoint(x: c.x, y: c.y + r), end: CGPoint(x: c.x, y: c.y - r), options: [])
	ctx.restoreGState()
	let ri = 160 * u
	ctx.setFillColor(NSColor(white: 0.1, alpha: 1).cgColor)
	ctx.fillEllipse(in: CGRect(x: c.x - ri, y: c.y - ri, width: 2 * ri, height: 2 * ri))
	// Muesca
	ctx.setFillColor(NSColor(white: 0.82, alpha: 1).cgColor)
	ctx.fill(CGRect(x: c.x - 22 * u, y: c.y + ri - 34 * u, width: 44 * u, height: 40 * u))
	// Pines en un arco de 180° por debajo del centro, con la muesca arriba (DIN de 5 pines visto de frente).
	ctx.setFillColor(NSColor(white: 0.85, alpha: 1).cgColor)
	let rp = 100 * u
	let pin = 30 * u
	for grados in stride(from: 180.0, through: 360.0, by: 45.0) {
		let a = CGFloat(grados) * .pi / 180
		let p = CGPoint(x: c.x + rp * cos(a), y: c.y + rp * sin(a))
		ctx.fillEllipse(in: CGRect(x: p.x - pin / 2, y: p.y - pin / 2, width: pin, height: pin))
	}
	ctx.restoreGState()
}

let args = CommandLine.arguments
guard args.count == 2 else { FileHandle.standardError.write("uso: dibujar_icono.swift <carpeta.iconset>\n".data(using: .utf8)!); exit(2) }
let carpeta = URL(fileURLWithPath: args[1], isDirectory: true)
try FileManager.default.createDirectory(at: carpeta, withIntermediateDirectories: true)
for lado in [16, 32, 128, 256, 512] {
	for escala in [1, 2] {
		let px = lado * escala
		let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
		                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
		dibujar(ctx, CGFloat(px))
		let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
		let nombre = "icon_\(lado)x\(lado)" + (escala == 2 ? "@2x" : "") + ".png"
		try rep.representation(using: .png, properties: [:])!.write(to: carpeta.appendingPathComponent(nombre))
	}
}
