import Vapor
import FluentProvider

final class PokemonController {

    // "Catches" a pokemon when posting to "pokemons/catch"
    static func catchPokemon(_ req: Request) throws -> ResponseRepresentable {
        guard let json = req.json else {
            throw Abort.badRequest
        }

        // Create and save pokemon to database
        let pokemon = try Pokemon(json: json)
        try pokemon.save()

        return pokemon
    }

    static func addRoutes(to drop: Droplet) {
        let pokemonGroup = drop.grouped("pokemons")
        pokemonGroup.post("catch", handler: catchPokemon)
    }
}