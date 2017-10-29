import App
import Vapor

let config = try Config()
try config.setup()

let drop = try Droplet(config)
// Sets up all routes associated with our Pokemon app
try drop.setupPokemonRoutes()

drop.get() { req in
    return "It works 🎉"
}

try drop.run()
