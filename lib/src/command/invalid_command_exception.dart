/// Exception thrown when a command cannot be processed.
class InvalidCommandException implements Exception {
  /// A message describing the validation exception.
  final String message;

  /// Creates a new [InvalidCommandException] with an optional [message].
  const InvalidCommandException([this.message = '']);

  /// Returns a description of the validation exception.
  ///
  /// The description always contains the [message].
  @override
  String toString() {
    return message.isEmpty
        ? '$InvalidCommandException'
        : '$InvalidCommandException: $message';
  }
}
