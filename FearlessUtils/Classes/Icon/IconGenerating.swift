import Foundation

enum IconGeneratingError: Error {
    case notImplemented
}

public protocol DrawableIcon {
    func drawInContext(_ context: CGContext, fillColor: UIColor, size: CGSize)
}

public protocol IconGenerating {
    func generateFromAddress(_ address: String) throws -> DrawableIcon
    func ethereumIconFromAddress(_ address: String) throws -> DrawableIcon
}

public extension IconGenerating {
    func ethereumIconFromAddress(_ address: String) throws -> DrawableIcon {
        throw IconGeneratingError.notImplemented
    }
}
