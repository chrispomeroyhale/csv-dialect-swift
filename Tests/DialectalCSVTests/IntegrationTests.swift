import XCTest
@testable import DialectalCSV

class IntegrationTests : XCTestCase {

    static var allTests = [
        ("testDocumentExportAgainstDocumentImport", testDocumentExportAgainstDocumentImport),
        ("testStreamInput", testStreamInput),
        ("testStreamOutput", testStreamOutput),
        ("testStreamInputToOutput", testStreamInputToOutput),
    ]

    let header = [HeaderFields.quote.rawValue, HeaderFields.author.rawValue]
    let authors = [Authors.mahatmaGandhi.rawValue, Authors.abrahamLincoln.rawValue, Authors.theodoreRoosevelt.rawValue]
    let quotes = [Quotes.mahatmaGandhi.rawValue, Quotes.abrahamLincoln.rawValue, Quotes.theodoreRoosevelt.rawValue]
    var records = Records()

    override func setUp() {
        self.records = [
            [quotes[0], authors[0]],
            [quotes[1], authors[1]],
            [quotes[2], authors[2]]
        ]
    }

    func testDocumentExportAgainstDocumentImport() {
        let documentExport = Document(header: header, records: records)
        let data = try? documentExport.export()
        XCTAssertNotNil(data)
        XCTAssert(data!.count != 0)

        let documentImport = try! Document(data: data!)
        XCTAssertEqual(documentImport.header!.count, 2)
        XCTAssertEqual(documentImport.records.count, 3)

        XCTAssertEqual(documentImport.records[0][0], quotes[0])
        XCTAssertEqual(documentImport.records[0][1], authors[0])

        XCTAssertEqual(documentImport.records[1][0], quotes[1])
        XCTAssertEqual(documentImport.records[1][1], authors[1])

        XCTAssertEqual(documentImport.records[2][0], quotes[2])
        XCTAssertEqual(documentImport.records[2][1], authors[2])
    }

    func testStreamInput() {
        let url = Utility.fixtureURL(named: "multipleRecords.csv")
        let inputFileHandle = try! FileHandle(forReadingFrom: url)
        let inputDocument = try? Document(fileHandle: inputFileHandle)
        XCTAssertNotNil(inputDocument)
        guard let document = inputDocument else {
            XCTFail()
            return
        }
        XCTAssertNotNil(document.header)
        XCTAssertEqual(document.header!.count, 2)
        XCTAssertEqual(document.records.count, 3)

        XCTAssertEqual(document.header![0], HeaderFields.quote.rawValue)
        XCTAssertEqual(document.header![1], HeaderFields.author.rawValue)

        XCTAssertEqual(document.records[0][0], Quotes.mahatmaGandhi.rawValue)
        XCTAssertEqual(document.records[0][1], Authors.mahatmaGandhi.rawValue)

        XCTAssertEqual(document.records[1][0], Quotes.abrahamLincoln.rawValue)
        XCTAssertEqual(document.records[1][1], Authors.abrahamLincoln.rawValue)
    }

    func testStreamOutput() {
        let document = Document(header: header, records: records)
        let outputURL = Utility.outputURL.appendingPathComponent("testStreamOutput.csv")
        FileManager.default.createFile(atPath: outputURL.path, contents: nil)
        let outputFileHandle = try! FileHandle(forWritingTo: outputURL)
        let result = try? document.export(fileHandle: outputFileHandle)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!)

        XCTAssertEqual(Utility.fixture(for: outputURL), Utility.fixture(named: "multipleRecords.csv"))
    }

    func testStreamInputToOutput() {
        let outputURL = Utility.outputURL.appendingPathComponent("testStreamInputToOutput.csv")
        FileManager.default.createFile(atPath: outputURL.path, contents: nil)
        let outputFileHandle = try! FileHandle(forWritingTo: outputURL)
        let outputHandler = OutputHandler(fileHandle: outputFileHandle)

        let inputURL = Utility.fixtureURL(named: "multipleRecords.csv")
        let inputFileHandle = try! FileHandle(forReadingFrom: inputURL)
        let inputHandler = InputHandler(fileHandle: inputFileHandle)
        inputHandler.delegate = outputHandler

        do {
            try inputHandler.readToEndOfFile()
        } catch {
            XCTFail()
        }

        XCTAssertEqual(Utility.fixture(for: inputURL), Utility.fixture(for: outputURL))
    }

}
