/// Error codes for form operations
enum FormOperationErrorCode {
  FORM_OPERATION_CANCELED,
  FORM_COULD_NOT_BE_OPEN,
  FORM_OPERATION_UNKNOWN_ERROR
}

/// Exception thrown when a form operation fails
class FormOperationException implements Exception {
  const FormOperationException({this.errorCode});

  /// The error code associated with this exception
  final FormOperationErrorCode? errorCode;

  @override
  String toString() => 'FormOperationException: $errorCode';
}
