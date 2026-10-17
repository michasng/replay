import 'dart:async';

import 'package:replay/src/internal/serial_queue.dart';
import 'package:test/test.dart';

void main() {
  group('SerialQueue', () {
    late SerialQueue queue;

    setUp(() {
      queue = SerialQueue();
    });

    group('when tasks overlap', () {
      test('runs them one at a time, in the order they were added', () async {
        final steps = <String>[];

        final first = queue.run(() async {
          steps.add('first started');
          await Future<void>.value();
          steps.add('first finished');
          return 'first result';
        });
        final second = queue.run(() async {
          steps.add('second started');
          return 'second result';
        });

        expect(await first, 'first result');
        expect(await second, 'second result');
        expect(steps, ['first started', 'first finished', 'second started']);
      });
    });

    group('when a task fails', () {
      test('passes the error to its caller and runs the next task', () async {
        final failing = queue.run<void>(() async => throw StateError('task'));
        final next = queue.run(() async => 'next result');

        await expectLater(failing, throwsStateError);
        expect(await next, 'next result');
      });
    });

    group('idle', () {
      test('completes once all added tasks have finished', () async {
        final finishedTasks = <String>[];
        unawaited(queue.run(() async => finishedTasks.add('first')));
        unawaited(queue.run(() async => finishedTasks.add('second')));

        await queue.idle;

        expect(finishedTasks, ['first', 'second']);
      });

      test('given no tasks, completes', () async {
        await expectLater(queue.idle, completes);
      });
    });
  });
}
