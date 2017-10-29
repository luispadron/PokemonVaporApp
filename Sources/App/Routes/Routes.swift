import Vapor

public extension Droplet {
    func setupPokemonRoutes() throws {
        try resource("pokemons", PokemonController.self)
    }
}