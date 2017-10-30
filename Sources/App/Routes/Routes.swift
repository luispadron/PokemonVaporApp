import Vapor

public extension Droplet {
    func setupPokemonRoutes() throws {
        let controller = PokemonController(droplet: self)
        controller.addRoutes()
    }
}
