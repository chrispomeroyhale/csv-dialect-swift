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
    }

    /**
        Export piecemeal rows to a UTF-8 encoded data representation. Each row ought to have the same number of values.
    */
    public func export(rows: [Row]) throws -> Data {
        guard rows.count > 0 else {
            return Data()
        }

        let rows = rows.map { (row: Row) -> String in
            let transformedLines = row.map { self.escaped(field: $0) }
            return transformedLines.joined(separator: self.dialect.delimiter)
        }

        let lineTerminator = String(self.dialect.lineTerminator)
        let string = rows.joined(separator: lineTerminator).appending(lineTerminator)

        guard let data = string.data(using: String.Encoding.utf8) else {
            throw ExportError.badEncoding
        }
        return data
    }

    private func escaped(field: String) -> String {
        let dialect = self.dialect
        if field == "" {
            return dialect.nullSequence ?? ""
        } else if let quote = dialect.quoteCharacter {
            let quoteString = String(quote)
            var escapedField = field
            if dialect.doubleQuote {
                escapedField = field.replacingOccurrences(of: quoteString, with: quoteString + quoteString)
            }
            return quoteString + escapedField + quoteString
        } else if let escape = dialect.escapeCharacter {
            let escapeString = String(escape)
            let escapedField = field.replacingOccurrences(of: escapeString, with: escapeString + escapeString)
            return escapedField.replacingOccurrences(of: dialect.delimiter, with: escapeString + dialect.delimiter)
        }

        return field
    }

}
