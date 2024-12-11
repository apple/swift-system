//TODO: make this not an enum
public enum IORingError: Error, Equatable {
    case missingRequiredFeatures
    case operationCanceled
    case unknown
}
