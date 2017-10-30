import Vapor
import FluentProvider

final class PokemonController {
    private static let apiUrl: String = "http://pokeapi.co/api/v2/pokemon/"

    let droplet: Droplet

    init(droplet: Droplet) {
        self.droplet = droplet
    }

    // "Catches" a pokemon when posting to "pokemons/catch"
    func catchPokemon(_ req: Request) throws -> ResponseRepresentable {
        guard let json = req.json else { throw Abort.badRequest }

        // Make an API Request to the PokeAPI and verify that the pokemon name is valid.
        let pokeName: String = try json.get(Pokemon.Keys.name)

        let response = try droplet.client.get(PokemonController.apiUrl + pokeName.lowercased())

        // Make sure pokemon exists
        guard response.data["id"]?.int != nil else {
            throw Abort(.badRequest, reason: "\(pokeName.lowercased()) is not a valid Pokèmon!")
        }

        // Create and save pokemon to database
        let pokemon = try Pokemon(json: json)
        try pokemon.save()

        return pokemon
    }

    // Lists all "caught" pokemon when accessing "/"
    func listPokemon(_ req: Request) throws -> ResponseRepresentable {
        return try Pokemon.all().makeJSON()
    }

    func getPokemon(_ req: Request) throws -> ResponseRepresentable {
        return try req.parameters.next(Pokemon.self)
    }

    func addRoutes() {
        let pokemonGroup = droplet.grouped("pokemons")
        pokemonGroup.get(handler: listPokemon)
        pokemonGroup.get(Pokemon.parameter, handler: getPokemon)
        pokemonGroup.post("catch", handler: catchPokemon)
    }
}
