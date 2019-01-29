import XCTest
@testable import DialectalCSV

class ExportTests : XCTestCase {

    static var allTests = [
        ("testNullSequenceValues", testNullSequenceValues),
    ]

    func testNullSequenceValues() {
        let records = [
            ["quote", "author"],
            ["", "null"],
            [Quotes.abrahamLincoln.rawValue, "   null"],
        ]
        var dialect = Dialect()
        dialect.nullSequence = "null"
        let document = Document(header: nil, records: records, dialect: dialect)
        guard let data = try? document.export(dialect: dialect) else {
            XCTFail()
            return
        }
        XCTAssertEqual(String(data: data, encoding: .utf8), String(data: Utility.fixture(named: "nullSequenceValues.csv"), encoding: .utf8))
    }

}
