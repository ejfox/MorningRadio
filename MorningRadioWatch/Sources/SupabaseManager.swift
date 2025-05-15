import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient

    private init() {
        let supabaseURL = URL(string: "https://xmdylmbdeulxcqdbkfno.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhtZHlsbWJkZXVseGNxZGJrZm5vIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODk5NTM0NjAsImV4cCI6MjAwNTUyOTQ2MH0.jspo2sHRd4RSN8jL8DYIfTdfZVoGZRcbiZL0MpHo8yI"
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }
} 