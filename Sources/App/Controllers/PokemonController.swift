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

    // Lists all "caught" pokemon when accessing "/"
    static func listPokemon(_ req: Request) throws -> ResponseRepresentable {
        return try Pokemon.all().makeJSON()
    }

    static func getPokemon(_ req: Request) throws -> ResponseRepresentable {
        return try req.parameters.next(Pokemon.self)
    }

    static func addRoutes(to drop: Droplet) {
        let pokemonGroup = drop.grouped("pokemons")
        pokemonGroup.get(handler: listPokemon)
        pokemonGroup.get(Pokemon.parameter, handler: getPokemon)
        pokemonGroup.post("catch", handler: catchPokemon)
    }
}