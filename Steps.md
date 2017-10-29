## Step 1

- Create Pokemon class.

```swift
import Foundation
import FluentProvider

final class Pokemon: Model {
    let storage = Storage()

    let name: String
    let date: Date

    init(name: String, date: Date) {
        self.name = name
        self.date = date
    }

    // Initializies a Pokemon object with a name, and time set to now
    convenience init(name: String) {
        self.init(name: name, date: Date())
    }

    // Keys for the database rows
    struct Keys {
        static let name = "name"
        static let date = "date"
    }

    // Construct a Pokemon object from a database row
    init (row: Row) throws {
        self.name = try row.get(Pokemon.Keys.name)
        self.date = try row.get(Pokemon.Keys.date)
    }

    // Construct a databse row from a Pokemon object
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Pokemon.Keys.name, self.name)
        try row.set(Pokemon.Keys.date, self.date)
        return row
    }
}

// Object preparations for insertion into database
extension Pokemon: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in 
            builder.id()
            builder.string(Pokemon.Keys.name)
            builder.date(Pokemon.Keys.date)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
```

- Go into `Config+Setup.swift` and add `preparations.append(Pokemon.self)` into `setupPreparations`.


## Step 2

- Conform Pokemon.swift to JSONConvertible

```swift
// Allows Pokemon object to be converted from/to JSON.
extension Pokemon: JSONConvertible {
    // Create a pokemon object using pure JSON
    convenience init (json: JSON) throws {
        try self.init(name: json.get(Pokemon.Keys.name), date: Date())
    }

    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Pokemon.Keys.id, self.id)
        try json.set(Pokemon.Keys.name, self.name)
        try json.set(Pokemon.Keys.date, self.date)
        return json
    }
}

// Allows us to return our Pokemon object as a response object!
extension Pokemon: ResponseRepresentable { }
```

- Create PokemonController.swift

```swift
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
```

- Create Routes.swift

```swift
import Vapor

public extension Droplet {
    func setupPokemonRoutes() throws {
        PokemonController.addRoutes(to: self)
    }
}
```

- Add routes setup to main.swift

```swift
// Sets up all routes associated with our Pokemon app
try drop.setupPokemonRoutes()
```

## Step 3

- Add list function

```swift
// Lists all "caught" pokemon when accessing "/"
static func listPokemon(_ req: Request) throws -> ResponseRepresentable {
    return try Pokemon.all().makeJSON()
}

// In addRroutes
pokemonGroup.post("catch", handler: catchPokemon)
```

Make sure to post a new pokemon then access.

- Add get function

```swift
static func getPokemon(_ req: Request) throws -> ResponseRepresentable {
    return try req.parameters.next(Pokemon.self)
}

// In addRoutes
pokemonGroup.get(Pokemon.parameter, handler: getPokemon)
```

Re-run post again and do "localhost:8080/pokemon/[id]"