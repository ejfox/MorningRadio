// ScrapStore.swift
// Defines the persistence interface used by AppIntents and the main app.

import Foundation

protocol ScrapStoreProtocol {
    func save(url: URL, notes: String?, tags: [TagEntity]?) async throws
}

enum ScrapStoreError: Error {
    case notImplemented
}

final class ScrapStore: ScrapStoreProtocol {
    static let shared = ScrapStore()
    private init() {}

    func save(url: URL, notes: String?, tags: [TagEntity]?) async throws {
        // TODO: Implement real persistence. For now, just pretend it succeeded.
        throw ScrapStoreError.notImplemented
    }
} 