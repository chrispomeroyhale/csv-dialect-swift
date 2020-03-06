import Foundation

/**
    Parses piecemeal CSV from a physical representation to a logical representation.

    ImportParser maintains the necessary state so that CSV data may be incrementally added and performs basic validation.
*/
public class ImportParser {

    public let dialect: Dialect
    private var characterSet = CharacterSet()

    public init(dialect: Dialect = Dialect()) {
        self.dialect = dialect

        characterSet.insert(charactersIn: dialect.lineTerminator)
        characterSet.insert(charactersIn: dialect.delimiter)
        if let quoteCharacter = dialect.quoteCharacter {
            characterSet.insert(charactersIn: String(quoteCharacter))
        }
        if let escapeCharacter = dialect.escapeCharacter {
            characterSet.insert(charactersIn: String(escapeCharacter))
        }
        characterSet.insert(charactersIn: " \t")
    }

    /**
        - badEncoding: Indicates input could not be decoded.
        - uncaughtCharacter: An unexpected character at a 1-indexed row number.
        - uneven: Encountered a row whose number of values is mismatched relative to other rows. All rows are expected to contain the same number of values.
    */
    public enum ImportError: Error {
    case badEncoding
    case uncaughtCharacter(UInt, Character)
    case uneven(UInt)
    }

    private var row = Row()
    private var field: Field = ""
    private var quoted: Bool = false
    private var lastSpecialCharacter: Character?
    private var rowNumber: UInt = 0
    private var fieldsCount: UInt?

    /**
        Transform a chunk of data CSV into in-memory rows.

        - Parameter data: A chunk of UTF-8 encoded CSV data. Transformation relies on the accuracy of its dialect. Data is expected to be inputted in order lest the parser state may become invalid.
        - Throws: ImportError
        - Returns: Parsed rows. An incomplete row is not returned prematurely until the data is provided or a flush command is issued.
        - Note: It is best practice to call the flush method after having parsed the last of the input data.
    */
    public func `import`(data: Data) throws -> [Row] {
        guard let string = String(data: data, encoding: String.Encoding.utf8) else {
            throw ImportError.badEncoding
        }

        let scanner: Scanner = Scanner(string: string)
        scanner.scanLocation = 0
        scanner.charactersToBeSkipped = nil

        var rows = [Row]()

        while true {
            var fieldPartition: NSString?
            if !scanner.scanUpToCharacters(from: characterSet, into: &fieldPartition), scanner.isAtEnd {
                break
            }

            if let partition = fieldPartition as String? {
                field += partition
            }

            var characters: NSString?
            if !scanner.scanCharacters(from: characterSet, into: &characters) {
                break
            }

            guard let specials = characters as String? else {
                break
            }

            for character in specials {
                switch character {
                case Character(dialect.delimiter):
                    // If escaped or if quoted, add. Otherwise terminate
                    let escaped = (dialect.escapeCharacter != nil && lastSpecialCharacter == dialect.escapeCharacter!)
                    if escaped || quoted {
                        field += dialect.delimiter
                    } else {
                        self.terminateField()
                    }
                case Character(" "):
                    fallthrough
                case Character("\t"):
                    // Optionally skip whitespace immediately after delimiter
                    if !(dialect.skipInitialSpace && !quoted && field.isEmpty) {
                        field += String(character)
                    }
                case Character(dialect.lineTerminator):
                    if !quoted {
                        rows.append(try self.terminateRow())
                    } else {
                        field += String(character)
                    }
                default:
                    if let escapeCharacter = dialect.escapeCharacter {
                        if lastSpecialCharacter == escapeCharacter {
                            field += String(escapeCharacter)
                        }
                    } else if let quoteCharacter = dialect.quoteCharacter, character == quoteCharacter {
                        if !quoted {
                            quoted = true
                            if dialect.doubleQuote, lastSpecialCharacter == dialect.quoteCharacter {
                                field += String(quoteCharacter)
                            }
                        } else {
                            let escapedQuote = !dialect.doubleQuote && dialect.escapeCharacter == lastSpecialCharacter
                            if escapedQuote {
                                field += String(quoteCharacter)
                            } else {
                                // Note: In doubleQuote mode, quoted will turn off and on again
                                quoted = false
                            }
                        }
                    } else if character == Character("\r"), dialect.lineTerminator == "\r\n" {
                        // Assumes \r is followed by \r\n to handle a special case
                    } else if character == Character("\n"), dialect.lineTerminator == "\r\n" {
                        // Special case for \r\n (CRLF) which we need to handle in the event the string gets split between characters
                        if lastSpecialCharacter == Character("\r"), !quoted {
                            rows.append(try self.terminateRow())
                        } else {
                            field += String(character)
                        }
                    } else {
                        throw ImportError.uncaughtCharacter(rowNumber + 1, character)
                    }
                }
                lastSpecialCharacter = character
            }
        }

        return rows
    }

    /**
        Terminate field and line such as when the file is missing an EOL.
    */
    public func flushRow() throws -> Row? {
        guard !field.isEmpty else {
            return nil
        }
        let terminatingRow = try self.terminateRow()
        return terminatingRow
    }

    private func terminateField() {
        // Differentiate null sequence
        let wasQuoted = (dialect.quoteCharacter != nil && lastSpecialCharacter == dialect.quoteCharacter!)
        if field == dialect.nullSequence, !wasQuoted {
            field = ""
        }
        // Terminate field
        row.append(field)
        field = ""
    }

    private func terminateRow() throws -> Row {
        var terminatingRow: Row

        self.terminateField()
        // Terminate row
        if let lastCount = fieldsCount, lastCount != row.count {
            throw ImportError.uneven(rowNumber + 1)
        }
        rowNumber += 1
        fieldsCount = UInt(row.count)
        terminatingRow = row
        row = Row()
        lastSpecialCharacter = nil

        return terminatingRow
    }

}
