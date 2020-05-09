import XCTest
@testable import DialectalCSV

class ExportTests : XCTestCase {

    static var allTests = [
        ("testEscapeCharacter", testEscapeCharacter),
        ("testNoRows", testNoRows),
        ("testNullSequenceValues", testNullSequenceValues),
    ]

    func testEscapeCharacter() {
        let rows = [
            ["\"quote\"", "\"author\""],
            ["The best way to find yourself is to lose yourself in the ,service, of others.", "'" + Authors.mahatmaGandhi.rawValue],
            ["Always bear in mind that your own resolution to succeed is more important than any 'other.", Authors.abrahamLincoln.rawValue],
        ]
        var dialect = Dialect()
        dialect.escapeCharacter = "'"
        let document = Document(allRows: rows, dialect: dialect)
        guard let data = try? document.export(dialect: dialect) else {
            XCTFail()
            return
        }
        let expected = Utility.fixture(named: "escapeCharacter.csv")
        XCTAssertEqual(String(data: data, encoding: .utf8), String(data: expected, encoding: .utf8))
    }

    func testNoRows() {
        let rows = [Row]()
        var dialect = Dialect()
        dialect.header = false
        let document = Document(allRows: rows, dialect: dialect)
        guard let data = try? document.export(dialect: dialect) else {
            XCTFail()
            return
        }
        XCTAssertTrue(data.isEmpty)
    }

    func testNullSequenceValues() {
        let rows = [
            ["quote", "author"],
            [nil, "null"],
            [Quotes.abrahamLincoln.rawValue, "   null"],
        ]
        var dialect = Dialect()
        dialect.nullSequence = "null"
        let document = Document(allRows: rows, dialect: dialect)
        guard let data = try? document.export(dialect: dialect) else {
            XCTFail()
            return
        }
        let expected = Utility.fixture(named: "nullSequenceValues.csv")
        XCTAssertEqual(String(data: data, encoding: .utf8), String(data: expected, encoding: .utf8))

        dialect.nullSequence = nil
        XCTAssertThrowsError(try document.export(dialect: dialect))
    }

}
