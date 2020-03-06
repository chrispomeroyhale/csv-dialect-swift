/**
    Convenience for iterating through a streaming input receiving its logical representation.

    - Note: Given the nature of `InputHandler` being an input stream, any iterator created by this sequence assigns itself as the handler's delegate. This means only one sequence operation should happen at a time.
*/
extension InputHandler: Sequence {

    // MARK: - Sequence

    public func makeIterator() -> InputIterator {
        return InputIterator(handler: self)
    }

}

public class InputIterator: IteratorProtocol {

    private(set) public var invalidated = false
    private(set) public var header: Header?
    private(set) public var recordBuffer = ArraySlice<Record>()
    private let handler: InputHandler

    /**
        - Note: Resets and reopens the handler if need be
    */
    public init(handler: InputHandler) {
        self.handler = handler

        // Ensure we reset which gets an opportunity to call its prior delegate
        _ = self.handler.reset()
        self.handler.delegate = self

        self.readHeader()
    }

    /**
        Read until a header is found (i.e. read the first row) if applicable
    */
    private func readHeader() {
        while !self.handler.isOpen, (try? self.handler.read()) != nil {}
    }

    // MARK: - IteratorProtocol

    public func next() -> Record? {
        do {
            while self.recordBuffer.isEmpty, try self.handler.read() {}
            return self.recordBuffer.popFirst()
        } catch {
            return nil
        }
    }

}

extension InputIterator: InputHandlerDelegate {

    public func open(header: Header?) throws {
        self.header = header
    }

    public func append(records: [Record]) throws {
        self.recordBuffer.append(contentsOf: records)
    }

    public func close() throws {}

    public func reset() {
        self.invalidated = true
        self.header = nil
        self.recordBuffer.removeAll(keepingCapacity: false)
    }

}
