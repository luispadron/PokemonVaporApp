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