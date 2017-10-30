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

## Step 4

- Modify PokemonController
	- Remove static
	- Add init

```swift
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
```

- Fix Routes.swift
- Go to config/droplet.json and change client to "foundation"

## Step 5

- Add LeafProvider
	- Package.swift
		`.package(url: "https://github.com/vapor/leaf-provider.git", .upToNextMajor(from: "1.1.0"))`
	- Then add to dependencies
- Add leaf in config for "view"

	`"view": "leaf",`
- Add `Resources/Views` folder
- Add `base.leaf`

```html
<!DOCTYPE html>
<html>
<head>
	<title>#import("title")</title>
	<link rel="stylesheet" href="/styles/app.css">
</head>
<body>

#import("content")

</body>
</html>
```

- Add `pokemon.leaf`

```html
#extend("base")

#export("title") { #(name) }

#export("content") {
    <h1>#(name)</h1>
    <img alt="#(name) Sprite" src="#(image)">
    <p>Caught on: #(date)</p>
}
```

- Update `getPokemon` function

```swift
func getPokemon(_ req: Request) throws -> ResponseRepresentable {
    let pokemon =  try req.parameters.next(Pokemon.self)
    let response = try droplet.client.get(PokemonController.apiUrl + pokemon.name.lowercased())
    // Get the pokemon sprite from API
    guard let pokemonSprite = response.data["sprites", "front_default"]?.string else {
        throw Abort(.badRequest, reason: "Unable to get sprite for pokemon \(pokemon.name)")
    }

    // Format the date
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    let dateString = formatter.string(from: pokemon.date)

    // Make the HTML view.
    return try droplet.view.make("pokemon", [
        "name": pokemon.name,
        "image": pokemonSprite,
        "date": dateString
    ])
}
```