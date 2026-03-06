class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([
    this.message = 'Session expired, please login again.',
  ]);

  @override
  String toString() => message;
}
