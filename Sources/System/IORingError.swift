//TODO: make this not an enum
public enum IORingError: Error, Equatable {
    case missingRequiredFeatures
    case operationCanceled
    case unknown(errorCode: Int)

    internal init(completionResult: Int32) {
        self = .unknown(errorCode: Int(completionResult)) //TODO, flesh this out
    }
}
