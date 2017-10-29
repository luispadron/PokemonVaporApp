import App
import Vapor

let config = try Config()
try config.setup()

let drop = try Droplet(config)

drop.get() { req in
    return "It works 🎉"
}

try drop.run()
