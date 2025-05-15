import AppIntents

// MARK: - ScrapEntity
struct ScrapEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Scrap")
    static var defaultQuery = ScrapEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        .init(title: "Scrap")
    }

    // MARK: - Properties
    let id: String
}

// MARK: - ScrapEntity Query
struct ScrapEntityQuery: EntityQuery {
    func entities(for identifiers: [ScrapEntity.ID]) async throws -> [ScrapEntity] {
        // TODO: Implement lookup when persistence exists.
        return identifiers.map { ScrapEntity(id: $0) }
    }

    func suggestedEntities() async throws -> [ScrapEntity] {
        // Return empty until we have persistence.
        return []
    }
}

// MARK: - TagEntity
struct TagEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Tag")
    static var defaultQuery = TagEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        .init(title: title)
    }

    // MARK: - Properties
    let id: String
    let title: String
}

// MARK: - TagEntity Query
struct TagEntityQuery: EntityQuery {
    func entities(for identifiers: [TagEntity.ID]) async throws -> [TagEntity] {
        // Placeholder implementation until persistence layer is ready.
        return identifiers.map { TagEntity(id: $0, title: $0) }
    }

    func suggestedEntities() async throws -> [TagEntity] {
        // Return empty until we have real data.
        return []
    }
} 