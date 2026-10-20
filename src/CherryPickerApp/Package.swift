// swift-tools-version:5.9
// CherryPicker: app AppKit para editar .midnam (fase 3, T-015, D-006). Diseño en docs/20_DISENO_APP.md.
// El ejecutable se empaqueta como .app con tools/empaquetar_app.sh.
import PackageDescription

let package = Package(
	name: "CherryPickerApp",
	platforms: [.macOS(.v13)],
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
