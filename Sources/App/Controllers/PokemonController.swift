import Vapor

final class PokemonController: ResourceRepresentable {
    // Called when going to "pokemons/"
    func index(_ req: Request) throws -> ResponseRepresentable {
        return try Pokemon.all().makeJSON()
    }

    func makeResource() -> Resource<Pokemon> {
        return Resource(
            index: index, 
            store: nil, 
            show: nil, 
            update: nil, 
            replace: nil,   
            destroy: nil, 
            clear: nil
        )
    }
}

// Just default conformance
extension PokemonController: EmptyInitializable { }