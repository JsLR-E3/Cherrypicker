// swift-tools-version:5.9
// Midnamer (antes CherryPicker; nombre propio, D-011): app AppKit para editar .midnam (fase 3, T-015, D-006). Diseño en docs/20_DISENO_APP.md.
// El ejecutable se empaqueta como .app con tools/empaquetar_app.sh.
import PackageDescription

let package = Package(
	name: "CherryPickerApp",
	platforms: [.macOS(.v13)],
	// El ejecutable se llama como la app; los módulos conservan el nombre del proyecto.
	products: [.executable(name: "Midnamer", targets: ["CherryPicker"])],
	dependencies: [
		.package(path: "../MidnamKit"),
	],
	targets: [
		// Lógica sin interfaz (filas de las tablas, etc.), con tests.
		.target(name: "CherryPickerCore", dependencies: ["MidnamKit"]),
		.executableTarget(name: "CherryPicker", dependencies: ["CherryPickerCore", "MidnamKit"]),
		.testTarget(name: "CherryPickerCoreTests", dependencies: ["CherryPickerCore", "MidnamKit"]),
	]
)
