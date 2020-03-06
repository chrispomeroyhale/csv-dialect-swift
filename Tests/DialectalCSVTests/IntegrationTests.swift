import XCTest
@testable import DialectalCSV

class IntegrationTests : XCTestCase {

    static var allTests = [
        ("testDocumentExportAgainstDocumentImport", testDocumentExportAgainstDocumentImport),
        ("testIterationStreamInput", testIterationStreamInput),
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

    // Tests iteration exposed by `InputBuffer`
    func testIterationStreamInput() {
        let inputURL = Utility.fixtureURL(named: "multipleRecords.csv")
        let inputHandler = try! InputHandler(from: inputURL)
        XCTAssertNotNil(try? inputHandler.readToEndOfFile())

        let iteratorA = inputHandler.makeIterator()

        // Iterator should be starting to read before any next() calls
        XCTAssertNotNil(iteratorA.header)
        XCTAssertEqual(iteratorA.header!.count, 2)

        // Pull first record with iterator A
        let record1 = iteratorA.next()
        XCTAssertNotNil(record1)
        XCTAssertEqual(record1!.count, 2)
        XCTAssertEqual(record1![0], Quotes.mahatmaGandhi.rawValue)
        XCTAssertEqual(record1![1], Authors.mahatmaGandhi.rawValue)

        // Start a new iterator B which should invalidate iterator A
        let iteratorB = inputHandler.makeIterator()
        XCTAssertTrue(iteratorA.invalidated)
        XCTAssertFalse(iteratorB.invalidated)
        XCTAssertNil(iteratorA.next())
        XCTAssertNotNil(iteratorB.next())

        // Switch to iterator B but leaving where iterator A left off
        let record2 = iteratorB.next()
        XCTAssertNotNil(record2)
        XCTAssertEqual(record2!.count, 2)
        XCTAssertEqual(record2![0], Quotes.abrahamLincoln.rawValue)
        XCTAssertEqual(record2![1], Authors.abrahamLincoln.rawValue)

        // Pull final record
        let record3 = iteratorB.next()
        XCTAssertNotNil(record3)
        XCTAssertEqual(record3!.count, 2)
        XCTAssertEqual(record3![0], Quotes.theodoreRoosevelt.rawValue)
        XCTAssertEqual(record3![1], Authors.theodoreRoosevelt.rawValue)

        // Ensure subsequent pulls ends the iteration
        let record4 = iteratorB.next()
        XCTAssertNil(record4)

        // Header information should be kept even after iteration ends
        XCTAssertNotNil(iteratorB.header)
        XCTAssertEqual(iteratorB.header!.count, 2)

        // Test a potential regression where the iterator might reset the stream after being nil once
        let record1_1 = iteratorB.next()
        XCTAssertNil(record1_1)
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
