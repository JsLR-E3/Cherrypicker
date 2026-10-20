// Arranque de la app sin nib: menú y controlador de documentos se crean en código.
import AppKit

let app = NSApplication.shared
// El primer NSDocumentController que se crea pasa a ser el compartido: tiene que ser el nuestro.
_ = MidnamDocumentController()
let delegate = AppDelegate()
app.delegate = delegate
app.mainMenu = MainMenu.build()
app.setActivationPolicy(.regular)
app.run()
