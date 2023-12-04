import Foundation

/**
    Convenience model for working with CSV in-memory.

    - Note: Take advantage of data streaming capabilities when possible instead of using this convenience class.
*/
public class Document: InputHandlerDelegate {

    /**
        Dialect that represents the initialized document records. Note that exporting does not use this dialect.
    */
    public let dialect: Dialect?

    public var header: Header?
    public var records = [Record]()

    /**
        Initialize an empty document.
    */
    public init(dialect: Dialect? = nil) {
        self.dialect = dialect
    }

    /**
        Initialize a document populated with records and an optional header.
    */
    public convenience init(header: Header?, records: [Record], dialect: Dialect? = nil) {
        self.init(dialect: dialect)
        self.header = header
        self.records = records
    }

    /**
        Initialize a document populated with rows. Extract and set the header if denoted by the dialect.
    */
    public convenience init(allRows: [Row], dialect: Dialect? = nil) {
        self.init(dialect: dialect)
        if let dialect = dialect, dialect.header {
            self.header = (allRows.first ?? []).compactMap { $0 }
            self.records = Array(allRows.dropFirst(1))
        } else {
            self.records = allRows
        }
    }

    /**
        Initialize a document from a data representation.

        - Parameter data: Data which comprises of the entire document as a UTF-8 string.
        - Parameter dialect: Dialect from which to parse against.
    */
    public convenience init(data: Data, dialect: Dialect = Dialect()) throws {
        let parser = ImportParser(dialect: dialect)
        var allRows = try parser.import(data: data)
        if let row = try parser.flushRow() {
            allRows.append(row)
        }
        self.init(allRows: allRows, dialect: dialect)
    }

    /**
        Initialize a document from a CSV-formatted file.

        - Note: Although this streams input data from the `FileHandle` the resulting document is still the full physical representation of the data.
    */
    public convenience init(fileHandle: FileHandle, dialect: Dialect = Dialect()) throws {
        self.init(dialect: dialect)
        let inputHandler = InputHandler(fileHandle: fileHandle, dialect: dialect)
        inputHandler.delegate = self
        try inputHandler.readToEndOfFile()
    }

    /**
        Export document to a UTF-8 encoded data representation.

        - Parameter dialect: Dialect to export against.
    */
    public func export(dialect: Dialect = Dialect()) throws -> Data {
        let parser = ExportParser(dialect: dialect)
        var data = Data()
        if let headerFields = self.header {
            data.append(try parser.export(rows: [headerFields]))
        }
        data.append(try parser.export(rows: self.records))
        return data
    }

    /**
        Export document to a CSV-formatted file.

        - Parameter dialect: Dialect to export against.
    */
    public func export(fileHandle: FileHandle, dialect: Dialect = Dialect()) throws -> Bool {
        let outputHandler = OutputHandler(fileHandle: fileHandle, dialect: dialect)
        try outputHandler.open(header: self.header)
        try outputHandler.append(records: self.records)
        try outputHandler.close()
        return true
    }

    /**
        - alreadyOpen: Indicates the document has already been initialized with data.
    */
    public enum InputError: Error {
    case alreadyOpen
    }

    // MARK: - InputHandlerDelegate

    /**
        - Note: Expects an empty document.
        - Throws: InputError
    */
    public func open(header: Header? = nil) throws {
        guard self.header == nil, self.records.count == 0 else {
            throw InputError.alreadyOpen
        }
        self.header = header
    }

    public func append(records: [Record]) throws {
        self.records.append(contentsOf: records)
    }

    public func close() throws {}

    public func reset() {}

}
