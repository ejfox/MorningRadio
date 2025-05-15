import Foundation
import AppIntents

/// App Intent that allows users (or the system) to save a URL and optional notes/tags to Scraps.
struct SaveScrapIntent: AppIntent {
    static var title: LocalizedStringResource = "Save to Scraps"
    static var description = IntentDescription("Save a web page or any URL into your Scraps collection.")

    // MARK: - Parameters

    @Parameter(title: "URL", requestValueDialog: "What URL do you want to save?")
    var url: URL

    @Parameter(title: "Notes", default: "", requestValueDialog: "Any notes for this scrap?")
    var notes: String

    @Parameter(title: "Tags")
    var tags: [TagEntity]?

    // MARK: - Perform

    func perform() async throws -> some IntentResult {
        try await ScrapStore.shared.save(url: url, notes: notes.isEmpty ? nil : notes, tags: tags)
        return .result(dialog: "Saved!")
    }
} 