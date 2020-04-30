/**
    A dialect describes the physical representations of CSV files. The same logical representation of CSV data may have different physical representations for compatibility with other software.
    SeeAlso: [CSV Dialect](https://frictionlessdata.io/specs/csv-dialect/)
*/
public struct Dialect: Equatable {
    public var delimiter: String = ","
    public var lineTerminator: String = "\r\n"
    public var quoteCharacter: Character? = "\"" {
        willSet {
            if newValue != nil {
                escapeCharacter = nil
            }
        }
    }
    public var doubleQuote: Bool = true
    public var escapeCharacter: Character? = nil {
        willSet {
            if newValue != nil {
                quoteCharacter = nil
            }
        }
    }
    public var nullSequence: String?
    public var skipInitialSpace: Bool = true
    public var header: Bool = true

    public init() {}
}
