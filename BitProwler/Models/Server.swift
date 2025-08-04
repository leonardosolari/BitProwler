import Foundation

protocol Server: Identifiable, Codable, Equatable {
    var id: UUID { get }
    var name: String { get set }
    var url: String { get set }
    
    var secret: String { get set }
    
    static var serversKey: String { get }
}