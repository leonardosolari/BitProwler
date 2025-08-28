import Foundation
import SwiftUI

enum SortDirection: Codable {
    case ascending
    case descending

    var systemImage: String {
        switch self {
        case .ascending:
            return "chevron.up"
        case .descending:
            return "chevron.down"
        }
    }
    
    mutating func toggle() {
        self = (self == .ascending) ? .descending : .ascending
    }
}

struct SortDescriptor<T: Codable & Equatable>: Codable, Equatable {
    var option: T
    var direction: SortDirection
}