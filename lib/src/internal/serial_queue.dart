import 'dart:async';

/// Runs tasks one at a time, in the order they were added.
class SerialQueue {
  Future<void> _previousTaskCompletion = Future.value();

  /// Runs [task] once all previously added tasks have finished.
  /// A failing task does not prevent later tasks from running.
  Future<T> run<T>(Future<T> Function() task) async {
    final previousTaskCompletion = _previousTaskCompletion;
    final taskCompletion = Completer<void>();
    _previousTaskCompletion = taskCompletion.future;
    try {
      await previousTaskCompletion;
      return await task();
    } finally {
      taskCompletion.complete();
    }
  }

  /// Completes once all tasks added so far have finished.
  Future<void> get idle => _previousTaskCompletion;
}
