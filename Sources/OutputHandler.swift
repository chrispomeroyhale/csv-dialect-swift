import Foundation

/**
    Redirects incremental input of a logical representation and outputs it to a physical representation via a write FileHandle.
*/
public class OutputHandler: InputHandlerDelegate {

    public let fileHandle: FileHandle
    public let dialect: Dialect
    public let parser: ExportParser

    /**
        - Parameter fileHandle: FileHandle for writing.
        - Parameter dialect: Dialect to export against.
    */
    public init(fileHandle: FileHandle, dialect: Dialect = Dialect()) {
        self.fileHandle = fileHandle
        self.dialect = dialect
        self.parser = ExportParser(dialect: dialect)
    }

    public convenience init(from url: URL, dialect: Dialect = Dialect()) throws {
        let fileHandle = try FileHandle(forWritingTo: url)
        self.init(fileHandle: fileHandle, dialect: dialect)
    }

    public convenience init?(atPath path: String, dialect: Dialect = Dialect()) {
        guard let fileHandle = FileHandle(forWritingAtPath: path) else {
            return nil
        }
        self.init(fileHandle: fileHandle, dialect: dialect)
    }

    // MARK: - InputHandlerDelegate

    public func open(header: Header? = nil) throws {
        if let headerFields = header {
            self.fileHandle.write(try self.parser.export(records: [headerFields]))
        }
    }

    public func append(records: Records) throws {
        self.fileHandle.write(try self.parser.export(records: records))
    }

    public func close() throws {
        self.fileHandle.closeFile()
    }

    public func reset() {}

}
