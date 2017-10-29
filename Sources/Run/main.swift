import App
import Vapor

let config = try Config()
try config.setup()

let drop = try Droplet(config)
try drop.setupPokemonRoutes()

drop.get() { req in
    return "It works 🎉"
}

try drop.run()
