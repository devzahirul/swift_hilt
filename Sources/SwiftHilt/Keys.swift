import Foundation

struct ServiceKey: Hashable, CustomStringConvertible {
    let typeID: ObjectIdentifier
    let typeName: String
    let qualifier: AnyHashable?

    init<T>(_ type: T.Type, qualifier: (any Qualifier)? = nil) {
        self.typeID = ObjectIdentifier(type)
        self.typeName = String(reflecting: type)
        self.qualifier = qualifier.map { AnyHashable($0) }
    }

    var description: String {
        if let qualifier = qualifier { return "\(typeName) \(qualifier)" }
        return typeName
    }
}
