import Foundation

/**
    A protocol for incrementally receiving a logical CSV representation.
*/
public protocol InputHandlerDelegate: class {

    /**
        Signal open with a header if one exists.

        - Throws: When the state is invalid.
    */
    func open(header: Header?) throws
    /**
        Append zero or more rows. Open should be called before append.

        - Throws: When the state is invalid.
    */
    func append(records: Records) throws
    /**
        Signal close. Once closed no more data is expected and the receiver should not be reopened.

        - Throws: When the state is invalid.
    */
    func close() throws

}

/**
    Parses a data stream using input from a read FileHandle and directs output to a InputHandlerDelegate. Allows for incremental parsing of a data stream at a maximum read byte size.
*/
public class InputHandler {

    public let fileHandle: FileHandle
    public let dialect: Dialect
    public let parser: ImportParser

    public static let defaultByteLength = 128

    /**
        Delegate responsible for handling events from the input stream.
    */
    public weak var delegate: InputHandlerDelegate?

    /**
        - Parameter fileHandle: FileHandle for reading. InputHandler should be solely responsible for controlling seeking behavior during its lifetime. The FileHandle's seek position should be at the beginning.
        - Parameter dialect: Dialect from which to parse against.
    */
    public init(fileHandle: FileHandle, dialect: Dialect = Dialect()) {
        self.fileHandle = fileHandle
        self.dialect = dialect
        self.parser = ImportParser(dialect: dialect)
    }

    public convenience init(from url: URL, dialect: Dialect = Dialect()) throws {
        let fileHandle = try FileHandle(forReadingFrom: url)
        self.init(fileHandle: fileHandle, dialect: dialect)
    }

    public convenience init?(atPath path: String, dialect: Dialect = Dialect()) {
        guard let fileHandle = FileHandle(forReadingAtPath: path) else {
            return nil
        }
        self.init(fileHandle: fileHandle, dialect: dialect)
    }

    deinit {
        try? self.close()
    }

    /**
        Whether any data has been read and the handler is still open. Should not be opened more than once.
    */
    private(set) public var `open` = false
    private var data = Data()

    /**
        Reads and parses a chunk of data from the FileHandle and directs output to its delegate.

        - Parameter length: Maximum byte length of data to read.
        - Return: Whether data was read. False indicates end of file.
    */
    public func read(length: Int = InputHandler.defaultByteLength) throws -> Bool {
        data.append(self.fileHandle.readData(ofLength: length))
        guard data.count > 0 else {
            try self.close()
            return false
        }

        var records = Records()
        do {
            records = try self.parser.import(data: data)
        } catch ImportParser.ImportError.badEncoding {
            return true // We may have broken utf8 in receiving incomplete data
        }
        var dropHeader = false

        if !self.open {
            self.open = true
            if self.dialect.header {
                try self.delegate?.open(header: records.first)
                dropHeader = true
            } else {
                try self.delegate?.open(header: nil)
            }
        }

        try self.delegate?.append(records: dropHeader ? Array(records.dropFirst()) : records)

        self.data = Data()

        return true
    }

    /**
        Convenience for reading the FileHandle and handling parsing through to the end of file.

        - Parameter length: Maximum byte length of data to read at each iteration.
    */
    public func readToEndOfFile(length: Int = InputHandler.defaultByteLength) throws {
        while try self.read(length: length) {}
    }

    /**
        Signals that the handler has received all data and is no longer
    */
    public func close() throws {
        if self.open {
            self.open = false
            if let row = try self.parser.flushRow() {
                try self.delegate?.append(records: [row])
            }
            try self.delegate?.close()
        }
    }

}
