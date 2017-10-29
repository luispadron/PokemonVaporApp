import Vapor

public extension Droplet {
    func setupPokemonRoutes() throws {
        PokemonController.addRoutes(to: self)
    }
}