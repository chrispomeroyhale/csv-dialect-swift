import Foundation

/**
    A protocol for sequentially receiving (i.e. streaming) a logical CSV representation. This protocol gives a chance to respond to the stream reading and parsing through `open`, `append`, and `close`, as well as to listen for user-initiated state change with `reset`.
*/
public protocol InputHandlerDelegate: class {

    /**
        Stream has began reading at the start and found a header if one exists.

        - Throws: When the state is invalid.
    */
    func open(header: Header?) throws

    /**
        Stream has found zero or more rows. Open ought to be be called before append.

        - Throws: When the state is invalid.
    */
    func append(records: [Record]) throws

    /**
        Stream has ended reading. Once closed no more data is expected and the receiver should not be reopened without an explicit reset.

        - Throws: When the state is invalid.
    */
    func close() throws

    /**
        Operator has reset the stream to the beginning and can be reopened.
    */
    func reset()

}

/**
    Parses a data stream using input from a read `FileHandle` and directs output to a `InputHandlerDelegate`. Allows for incremental parsing of a data stream at a maximum read byte size.
*/
public class InputHandler {

    public static let defaultByteLength = 128
    public static let defaultMaxRetries = 3

    /**
        Delegate responsible for handling events from the input stream.
    */
    public weak var delegate: InputHandlerDelegate?
    public let dialect: Dialect

    /**
        Whether any data has been read and the handler is still open.

        Should not be opened more than once unless reset. Opening suggests a header has been read (if applicable)
    */
    private(set) public var isOpen = false
    private var data = Data()
    private let maxRetries: Int
    private var retries: Int = 0
    private let fileHandle: FileHandle
    private let encoding: String.Encoding
    private var parser: ImportParser

    /**
        - Parameter fileHandle: FileHandle for reading. InputHandler should be solely responsible for controlling seeking behavior during its lifetime. The FileHandle's seek position should be at the beginning.
        - Parameter dialect: Dialect from which to parse against.
        - Parameter maxRetries: Maximum number of allowed consecutive retries
    */
    public init(fileHandle: FileHandle, encoding: String.Encoding = .utf8, dialect: Dialect = Dialect(), maxRetries: Int = InputHandler.defaultMaxRetries) {
        self.fileHandle = fileHandle
        self.encoding = encoding
        self.dialect = dialect
        self.maxRetries = maxRetries
        self.parser = ImportParser(dialect: dialect)
    }

    public convenience init(from url: URL, encoding: String.Encoding = .utf8, dialect: Dialect = Dialect(), maxRetries: Int = InputHandler.defaultMaxRetries) throws {
        let fileHandle = try FileHandle(forReadingFrom: url)
        self.init(fileHandle: fileHandle, encoding: encoding, dialect: dialect, maxRetries: maxRetries)
    }

    public convenience init?(atPath path: String, encoding: String.Encoding = .utf8, dialect: Dialect = Dialect(), maxRetries: Int = InputHandler.defaultMaxRetries) {
        guard let fileHandle = FileHandle(forReadingAtPath: path) else {
            return nil
        }
        self.init(fileHandle: fileHandle, encoding: encoding, dialect: dialect, maxRetries: maxRetries)
    }

    deinit {
        try? self.close()
    }

    /**
        Reads and parses a chunk of data from the FileHandle and directs output to its delegate.

        - Parameter length: Maximum number of bytes of data to read.
        - Returns: Whether data was read and to continue reading. Data may have been buffered. False indicates end of file.
        - Throws: May throw anything the `InputHandlerDelegate` or `ImportParser` throws. If thrown, state should be assumed to be invalid and should be reset before attempting to read again.
    */
    public func read(length: Int = InputHandler.defaultByteLength) throws -> Bool {
        data.append(self.fileHandle.readData(ofLength: length))
        guard data.count > 0 else {
            try self.close()
            return false
        }

        var rows = [Row]()
        do {
            rows = try self.parser.import(data: data, encoding: encoding)
        } catch ImportParser.ImportError.badEncoding {
            self.retries += 1
            // We may have received incomplete data that broke UTF-8 decoding due to variable byte widths
            // We give the reader an opportunity to read more before throwing that error
            guard self.retries <= self.maxRetries else {
                throw ImportParser.ImportError.badEncoding
            }
            return true
        }
        var dropHeader = false

        if !self.isOpen, rows.count > 0 {
            self.isOpen = true
            if self.dialect.header {
                let header = rows.first?.compactMap { $0 }
                try self.delegate?.open(header: header)
                dropHeader = true
            } else {
                try self.delegate?.open(header: nil)
            }
        }

        try self.delegate?.append(records: dropHeader ? Array(rows.dropFirst()) : rows)

        self.data = Data()
        self.retries = 0

        return true
    }

    /**
        Convenience for reading the FileHandle and handling parsing through to the end of file.

        - Parameter length: Maximum number of bytes of data to read at each iteration.
    */
    public func readToEndOfFile(length: Int = InputHandler.defaultByteLength) throws {
        while try self.read(length: length) {}
    }

    /**
        Resets internal state for reading from the beginning again. Closes will not be issued

        - Return: Whether the reset was successful
    */
    public func reset() -> Bool {
        let startOffset: UInt64 = 0
        if #available(iOS 13, macOS 10.15, *) {
            do {
                try self.fileHandle.seek(toOffset: startOffset)
            } catch {
                return false
            }
        } else {
            // Note: This method been deprecated because it could potentially raise an exception when it isn't marked as throw
            self.fileHandle.seek(toFileOffset: startOffset)
        }
        self.parser = ImportParser(dialect: dialect)
        self.isOpen = false
        self.data = Data()
        self.retries = 0
        self.delegate?.reset()
        return true
    }

    /**
        Signals that the handler has received all data ("end of file") and is no longer accepting additional reads
    */
    private func close() throws {
        if self.isOpen {
            self.isOpen = false
            if let row = try self.parser.flushRow() {
                try self.delegate?.append(records: [row])
            }
            try self.delegate?.close()
        }
    }

}
