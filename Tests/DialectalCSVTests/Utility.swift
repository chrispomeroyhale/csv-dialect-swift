import Foundation

enum HeaderFields: String {
    case quote = "quote", author = "author"
}

enum Authors: String {
    case abrahamLincoln = "Abraham Lincoln", mahatmaGandhi = "Mahatma Gandhi", theodoreRoosevelt = "Theodore Roosevelt"
}

enum Quotes: String {
    case abrahamLincoln = "Always bear in mind that your own resolution to succeed is more important than any other."
    case mahatmaGandhi = "The best way to find yourself is to lose yourself in the service of others."
    case theodoreRoosevelt = "The joy of living is his who has the heart to demand it."
}

class Utility {

    static func fixture(for url: URL) -> Data {
        return FileManager.default.contents(atPath: url.path)!
    }

    static func fixture(named fileName: String) -> Data {
        let url = Utility.fixtureURL(named: fileName)
        return Utility.fixture(for: url)
    }

    static func fixtureURL(named fileName: String) -> URL {
        var url = URL(fileURLWithPath: ".")
        url.appendPathComponent("Tests")
        url.appendPathComponent("DialectalCSVTests")
        url.appendPathComponent("Fixtures")
        url.appendPathComponent(fileName)
        return url
    }

    static let executionUUID = UUID().uuidString

    static var outputURL: URL {
        var url = URL(fileURLWithPath: ".")
        url.appendPathComponent(".build")
        url.appendPathComponent("tests")
        url.appendPathComponent(executionUUID)
        try! FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true)
        return url
    }

}

extension Array {

    subscript(safe index: Index) -> Element? {
        guard index < endIndex, index >= startIndex else { return nil }
        return self[index]
    }

}

import DialectalCSV

class SpyInputHandlerDelegate: InputHandlerDelegate {

    private(set) var records = [Record]()

    public func open(header: Header? = nil) throws {}

    public func append(records: [Record]) throws {
        self.records.append(contentsOf: records)
    }

    public func close() throws {}

    public func reset() {}

}
