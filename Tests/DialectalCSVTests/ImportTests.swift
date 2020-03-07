import XCTest
@testable import DialectalCSV

class ImportTests: XCTestCase {

    static var allTests = [
        ("testEscapeDoubleQuote", testEscapeDoubleQuote),
        ("testEscapeSlash", testEscapeSlash),
        ("testHeadersOnly", testHeadersOnly),
        ("testLeadingWhitespace", testLeadingWhitespace),
        ("testLineFeedOnly", testLineFeedOnly),
        ("testLineTerminatorStreamSplit", testLineTerminatorStreamSplit),
        ("testMissingEndOfLine", testMissingEndOfLine),
        ("testMissingHeaders", testMissingHeaders),
        ("testMixedLineTerminator", testMixedLineTerminator),
        ("testMultipleLines", testMultipleLines),
        ("testMultipleRecords", testMultipleRecords),
        ("testNoQuotes", testNoQuotes),
        ("testNullSequenceValues", testNullSequenceValues),
        ("testNullValues", testNullValues),
        ("testTrailingComma", testTrailingComma),
        ("testUnescapedQuotes", testUnescapedQuotes),
        ("testUnquotedHeaders", testUnquotedHeaders),
    ]

    func testEscapeDoubleQuote() {
        let data = Utility.fixture(named: "escapeDoubleQuote.csv")
        let document = try! Document(data: data)

        XCTAssertEqual(document.header!.count, 2)
        XCTAssertEqual(document.records.count, 2)

        XCTAssertEqual(document.records[0][0], "The best way to find yourself is to lose yourself in the \"service\" of others.")
        XCTAssertEqual(document.records[0][1], Authors.mahatmaGandhi.rawValue)

        XCTAssertEqual(document.records[1][0], "Always bear in mind that your own \"resolution to succeed is more important than any other.")
        XCTAssertEqual(document.records[1][1], Authors.abrahamLincoln.rawValue)
    }

    func testEscapeSlash() {
        let data = Utility.fixture(named: "escapeSlash.csv")
        var dialect = Dialect()
        dialect.escapeCharacter = "\\"
        dialect.doubleQuote = false
        let document = try! Document(data: data, dialect: dialect)

        XCTAssertEqual(document.header!.count, 2)
        XCTAssertEqual(document.records.count, 1)

        XCTAssertEqual(document.records[0][0], "The best way to find yourself is to lose yourself in the ,service, of others.")
        XCTAssertEqual(document.records[0][1], Authors.mahatmaGandhi.rawValue)
    }

    func testHeadersOnly() {
        let data = Utility.fixture(named: "headersOnly.csv")
        let document = try! Document(data: data)

        XCTAssertEqual(document.header!.count, 2)
        XCTAssertEqual(document.records.count, 0)
    }

    func testLeadingWhitespace() {
        let data = Utility.fixture(named: "leadingWhitespace.csv")
        let excludeLeadingSpace = try! Document(data: data)

        XCTAssertEqual(excludeLeadingSpace.header!.count, 2)
        XCTAssertEqual(excludeLeadingSpace.records.count, 3)

        XCTAssertEqual(excludeLeadingSpace.records[0][0], "   " + Quotes.mahatmaGandhi.rawValue)
        XCTAssertEqual(excludeLeadingSpace.records[0][1], Authors.mahatmaGandhi.rawValue)

        XCTAssertEqual(excludeLeadingSpace.records[1][0], Quotes.abrahamLincoln.rawValue + "  ")
        XCTAssertEqual(excludeLeadingSpace.records[1][1], Authors.abrahamLincoln.rawValue)

        XCTAssertEqual(excludeLeadingSpace.records[2][0], Quotes.theodoreRoosevelt.rawValue)
        XCTAssertEqual(excludeLeadingSpace.records[2][1], Authors.theodoreRoosevelt.rawValue)

        var dialect = Dialect()
        dialect.skipInitialSpace = false
        let includeLeadingSpace = try! Document(data: data, dialect: dialect)

        XCTAssertEqual(includeLeadingSpace.header!.count, 2)
        XCTAssertEqual(includeLeadingSpace.records.count, 3)

        XCTAssertEqual(includeLeadingSpace.records[0][0], "   " + Quotes.mahatmaGandhi.rawValue)
        XCTAssertEqual(includeLeadingSpace.records[0][1], "   " + Authors.mahatmaGandhi.rawValue)

        XCTAssertEqual(includeLeadingSpace.records[1][0], Quotes.abrahamLincoln.rawValue + "  ")
        XCTAssertEqual(includeLeadingSpace.records[1][1], "\t" + Authors.abrahamLincoln.rawValue)

        XCTAssertEqual(includeLeadingSpace.records[2][0], Quotes.theodoreRoosevelt.rawValue)
        XCTAssertEqual(includeLeadingSpace.records[2][1], "\t " + Authors.theodoreRoosevelt.rawValue)
    }

    func testLineFeedOnly() {
        let data = Utility.fixture(named: "lineFeedOnly.csv")
        var dialect = Dialect()
        dialect.lineTerminator = "\n"
        let document = try! Document(data: data, dialect: dialect)

        XCTAssertEqual(document.header!.count, 2)
        XCTAssertEqual(document.records.count, 1)
    }

    func testLineTerminatorStreamSplit() {
        let inputURL = Utility.fixtureURL(named: "lineTerminatorStreamSplit.csv")
        var dialect = Dialect()
        dialect.header = false
        let inputFileHandle = try! FileHandle(forReadingFrom: inputURL)
        let inputHandler = InputHandler(fileHandle: inputFileHandle, dialect: dialect)

        class Handler: InputHandlerDelegate {
            var records = [Record]()

            public func open(header: Header? = nil) throws {}

            public func append(records: [Record]) throws {
                self.records.append(contentsOf: records)
            }

            public func close() throws {}

            public func reset() {}
        }
        let handler = Handler()
        inputHandler.delegate = handler

        do {
            try inputHandler.readToEndOfFile(length: 8)
        } catch {
            XCTFail()
        }

        XCTAssertEqual(handler.records.count, 2)

        XCTAssertEqual(handler.records[0][0], "abc")
        XCTAssertEqual(handler.records[0][1], "xyz")

        XCTAssertEqual(handler.records[1][0], "123")
        XCTAssertEqual(handler.records[1][1], "456")
    }

    func testMissingEndOfLine() {
        let data = Utility.fixture(named: "missingEndOfLine.csv")
        let document = try! Document(data: data)

        XCTAssertEqual(document.header!.count, 2)
        XCTAssertEqual(document.records.count, 1)
    }

    func testMissingHeaders() {
        let data = Utility.fixture(named: "missingHeaders.csv")
        var dialect = Dialect()
        dialect.header = false
        let document = try! Document(data: data, dialect: dialect)

        XCTAssertNil(document.header)
        XCTAssertEqual(document.records.count, 1)

        let exportData = try? document.export()
        XCTAssertNotNil(exportData!)
        XCTAssert(exportData!.count != 0)

        let string = String(data: data, encoding: .utf8)
        let exportString = String(data: exportData!, encoding: .utf8)
        XCTAssertEqual(string, exportString)
    }

    func testMixedLineTerminator() {
        let data = Utility.fixture(named: "mixedLineTerminator.csv")
        let document = try! Document(data: data)

        XCTAssertEqual(document.header!.count, 2)
        XCTAssertEqual(document.records.count, 2)

        XCTAssertEqual(document.records[0][0], "Always bear in mind that your own resolution to succeed\nis more important than any other.")
        XCTAssertEqual(document.records[0][1], Authors.abrahamLincoln.rawValue)

        XCTAssertEqual(document.records[1][0], Quotes.mahatmaGandhi.rawValue)
        XCTAssertEqual(document.records[1][1], Authors.mahatmaGandhi.rawValue)
    }

    func testMultipleLines() {
        let data = Utility.fixture(named: "multipleLines.csv")
        let document = try! Document(data: data)

        XCTAssertEqual(document.header!.count, 2)
        XCTAssertEqual(document.records.count, 1)

        XCTAssertEqual(document.records[0][0], Quotes.abrahamLincoln.rawValue.split(separator: " ").joined(separator: "\r\n"))
        XCTAssertEqual(document.records[0][1], Authors.abrahamLincoln.rawValue.split(separator: " ").joined(separator: "\r\n"))
    }

    func testMultipleRecords() {
        let data = Utility.fixture(named: "multipleRecords.csv")
        let document = try! Document(data: data)

        XCTAssertEqual(document.header!.count, 2)
        XCTAssertEqual(document.records.count, 3)

        XCTAssertEqual(document.header![0], HeaderFields.quote.rawValue)
        XCTAssertEqual(document.header![1], HeaderFields.author.rawValue)

        XCTAssertEqual(document.records[0][0], Quotes.mahatmaGandhi.rawValue)
        XCTAssertEqual(document.records[0][1], Authors.mahatmaGandhi.rawValue)

        XCTAssertEqual(document.records[1][0], Quotes.abrahamLincoln.rawValue)
        XCTAssertEqual(document.records[1][1], Authors.abrahamLincoln.rawValue)

        XCTAssertEqual(document.records[2][0], Quotes.theodoreRoosevelt.rawValue)
        XCTAssertEqual(document.records[2][1], Authors.theodoreRoosevelt.rawValue)
    }

    func testNoQuotes() {
        let data = Utility.fixture(named: "noQuotes.csv")
        let document = try! Document(data: data)

        XCTAssertEqual(document.header!.count, 2)
        XCTAssertEqual(document.records.count, 2)

        XCTAssertEqual(document.records[0][0], Quotes.mahatmaGandhi.rawValue)
        XCTAssertEqual(document.records[0][1], Authors.mahatmaGandhi.rawValue)

        XCTAssertEqual(document.records[1][0], Quotes.abrahamLincoln.rawValue)
        XCTAssertEqual(document.records[1][1], Authors.abrahamLincoln.rawValue)
    }

    func testNullSequenceValues() {
        let data = Utility.fixture(named: "nullSequenceValues.csv")
        var dialect = Dialect()
        dialect.nullSequence = "null"
        let document = try! Document(data: data, dialect: dialect)

        XCTAssertEqual(document.header!.count, 2)
        XCTAssertEqual(document.records.count, 2)

        XCTAssertEqual(document.records[0][0], nil)
        XCTAssertEqual(document.records[0][1], "null")

        XCTAssertEqual(document.records[1][0], Quotes.abrahamLincoln.rawValue)
        XCTAssertEqual(document.records[1][1], "   null")
    }

    func testNullValues() {
        let data = Utility.fixture(named: "nullValues.csv")
        var dialect = Dialect()
        dialect.skipInitialSpace = false
        let document = try! Document(data: data, dialect: dialect)

        XCTAssertEqual(document.header!.count, 2)
        XCTAssertEqual(document.records.count, 2)

        XCTAssertEqual(document.records[0][0], "")
        XCTAssertEqual(document.records[0][1], "")

        XCTAssertEqual(document.records[1][0], Quotes.abrahamLincoln.rawValue)
        XCTAssertEqual(document.records[1][1], "   ")
    }

    func testTrailingComma() {
        let data = Utility.fixture(named: "trailingCommas.csv")
        let document = try! Document(data: data)

        XCTAssertEqual(document.header!.count, 3)
        XCTAssertEqual(document.records.count, 2)

        XCTAssertEqual(document.records[0][0], Quotes.abrahamLincoln.rawValue)
        XCTAssertEqual(document.records[0][1], Authors.abrahamLincoln.rawValue)
        XCTAssertEqual(document.records[0][2], "")

        XCTAssertEqual(document.records[1][0], Quotes.mahatmaGandhi.rawValue)
        XCTAssertEqual(document.records[1][1], Authors.mahatmaGandhi.rawValue)
        XCTAssertEqual(document.records[1][2], "")
    }

    func testUnescapedQuotes() {
        let data = Utility.fixture(named: "unescapedQuotes.csv")
        let document = try? Document(data: data)
        XCTAssertNil(document)
    }

    func testUnevenRecords() {
        var document: Document?
        do {
            let data = Utility.fixture(named: "unevenRecords.csv")
            document = try Document(data: data)
        } catch ImportParser.ImportError.uneven(let recordNumber) {
            XCTAssertEqual(recordNumber, 2)
        } catch {
            XCTFail()
        }
        XCTAssertNil(document)
    }

    func testUnquotedHeaders() {
        let data = Utility.fixture(named: "unquotedHeaders.csv")
        let document = try! Document(data: data)

        XCTAssertEqual(document.header!.count, 2)
        XCTAssertEqual(document.records.count, 1)

        XCTAssertEqual(document.header![0], HeaderFields.quote.rawValue)
        XCTAssertEqual(document.header![1], HeaderFields.author.rawValue + " name")
    }

}
