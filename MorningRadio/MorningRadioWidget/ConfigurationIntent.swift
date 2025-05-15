import AppIntents
import WidgetKit

struct ConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Widget"
    static var description: LocalizedStringResource = "Customize your Morning Radio widget."
    
    // Allow selecting a specific scrap index to display
    @Parameter(title: "Start Index", default: 0)
    var startIndex: Int
}

enum ColorTheme: String, AppEnum {
    case cyan
    case green
    case magenta
    case orange
    case red
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Color Theme"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .cyan: "Cyan (Default)",
        .green: "Matrix Green",
        .magenta: "Neon Magenta",
        .orange: "Amber Terminal",
        .red: "Red Alert"
    ]
    
    var primaryColor: Color {
        switch self {
        case .cyan: return .cyan
        case .green: return .green
        case .magenta: return .pink
        case .orange: return .orange
        case .red: return .red
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .cyan: return .blue
        case .green: return .mint
        case .magenta: return .purple
        case .orange: return .yellow
        case .red: return .pink
        }
    }
    
    var accentColor: Color {
        switch self {
        case .cyan: return .white
        case .green: return .white
        case .magenta: return .white
        case .orange: return .white
        case .red: return .white
        }
    }
} 