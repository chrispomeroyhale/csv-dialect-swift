import Foundation

/**
    Parses piecemeal CSV from a logical representation to a physical representation.
*/
public class ExportParser {

    public let dialect: Dialect

    public init(dialect: Dialect = Dialect()) {
        self.dialect = dialect
    }

    /**
        - badEncoding: Unable to convert rows into UTF-8 encoded data.
    */
    public enum ExportError: Error {
    case badEncoding
    case conflictingInput
    }

    /**
        Export piecemeal rows to a UTF-8 encoded data representation. Each row ought to have the same number of values.
    */
    public func export(rows: [Row]) throws -> Data {
        guard rows.count > 0 else {
            return Data()
        }

        let rows = try rows.map { (row: Row) -> String in
            let transformedLines = try row.map { try self.escaped(field: $0) }
            return transformedLines.joined(separator: self.dialect.delimiter)
        }

        let lineTerminator = String(self.dialect.lineTerminator)
        let string = rows.joined(separator: lineTerminator).appending(lineTerminator)

        guard let data = string.data(using: String.Encoding.utf8) else {
            throw ExportError.badEncoding
        }
        return data
    }

    private func escaped(field: Field) throws -> String {
        guard let unwrappedField = field else {
            guard let nullSequence = dialect.nullSequence else {
                throw ExportError.conflictingInput
            }
            return nullSequence
        }
        let dialect = self.dialect
        if let quote = dialect.quoteCharacter {
            let quoteString = String(quote)
            var escapedField = unwrappedField
            if dialect.doubleQuote {
                escapedField = unwrappedField.replacingOccurrences(of: quoteString, with: quoteString + quoteString)
            }
            return quoteString + escapedField + quoteString
        } else if let escape = dialect.escapeCharacter {
            let escapeString = String(escape)
            let escapedField = unwrappedField.replacingOccurrences(of: escapeString, with: escapeString + escapeString)
            return escapedField.replacingOccurrences(of: dialect.delimiter, with: escapeString + dialect.delimiter)
        }

        return unwrappedField
    }

}
