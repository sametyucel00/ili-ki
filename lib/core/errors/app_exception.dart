class AppException implements Exception {
  const AppException(this.message, {this.code = 'unknown'});

  final String message;
  final String code;

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}
