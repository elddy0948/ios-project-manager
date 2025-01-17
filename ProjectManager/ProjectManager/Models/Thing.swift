import Foundation

final class Thing: NSObject, Codable {
    var id: String? = nil
    var title: String? = nil
    var detail: String? = nil
    var state: State? = nil
    var dueDate: Double? = nil
    var updatedAt: String? = nil
    
    init(id: String? = nil, title: String?, description: String?, state: State?, dueDate: Double?, updatedAt: String? = nil) {
        self.id = id
        self.title = title
        self.detail = description
        self.state = state
        self.dueDate = dueDate
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, state, dueDate, updatedAt
        case detail = "description"
    }
    
    static func ==(lhs: Thing, rhs: Thing) -> Bool {
        return lhs.id == rhs.id
    }
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        return hasher.finalize()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? Thing else { return false }
        return self.id == object.id
    }
}

//MARK: - NSItemProviderWriting -
extension Thing: NSItemProviderWriting {
    static var writableTypeIdentifiersForItemProvider: [String] {
        return ["com.project-manager"]
    }
    
    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        let progress = Progress(totalUnitCount: 100)
        do {
            let data = try JSONEncoder().encode(self)
            progress.completedUnitCount = 100
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        return progress
    }
}

//MARK: - NSItemProviderReading -
extension Thing: NSItemProviderReading {
    static var readableTypeIdentifiersForItemProvider: [String] {
        return ["com.project-manager"]
    }
    
    static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Thing {
        let decoder = JSONDecoder()
        do {
            let subject = try decoder.decode(Thing.self, from: data)
            return subject
        } catch {
            fatalError("\(error)")
        }
    }
}
