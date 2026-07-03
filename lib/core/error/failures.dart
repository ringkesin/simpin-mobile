/// Base class for all failures in the application
/// Mirip seperti Either<Failure, Success> di functional programming
abstract class Failure {
  final String message;
  const Failure(this.message);
}

/// Failure yang datang dari server/API
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error']) : super(message);
}

/// Failure yang datang dari network (no connection, timeout, dll)
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error']) : super(message);
}

/// Failure untuk cache/local storage
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error']) : super(message);
}

/// Failure untuk validasi input
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Validation error']) : super(message);
}
