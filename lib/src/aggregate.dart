import 'dart:async';

import 'package:replay/src/command/command_decider.dart';
import 'package:replay/src/event/event_reducer.dart';
import 'package:replay/src/event/reduction.dart';
import 'package:replay/src/event_storage/event_storage.dart';
import 'package:replay/src/event_storage/in_memory_event_storage.dart';
import 'package:replay/src/internal/serial_queue.dart';
import 'package:replay/src/option/option_finder.dart';

const _closedMessage = 'Cannot process commands after close';

/// Sets / Omits optional generic parameters.
/// Mainly exists for backwards compatibility.
typedef Aggregate<TCommand, TEvent, TState> =
    AggregateFullyGeneric<TCommand, TEvent, TState, dynamic>;

class AggregateFullyGeneric<TCommand, TEvent, TState, TOption> {
  final OptionFinder<TOption, TState>? _optionFinder;
  final CommandDecider<TCommand, TEvent, TState> _commandDecider;
  final EventReducer<TEvent, TState> _eventReducer;

  final _commandQueue = SerialQueue();
  final _eventsController =
      StreamController<Reduction<TEvent, TState>>.broadcast();
  bool _isClosed = false;

  TState _state;
  TState get currentState => _state;

  final EventStorage<TEvent> eventStorage;

  /// Notifies about every committed event, after its commit.
  /// Replayed events are not included.
  Stream<Reduction<TEvent, TState>> get events => _eventsController.stream;

  AggregateFullyGeneric._({
    required TState initialState,
    required this._optionFinder,
    required this._commandDecider,
    required this._eventReducer,
    required this.eventStorage,
  }) : _state = initialState;

  /// Creates an aggregate and replays all events of [eventStorage] onto [initialState].
  /// Without an [eventStorage], events are kept in memory.
  static Future<AggregateFullyGeneric<TCommand, TEvent, TState, TOption>>
  load<TCommand, TEvent, TState, TOption>({
    required TState initialState,
    OptionFinder<TOption, TState>? optionFinder,
    required CommandDecider<TCommand, TEvent, TState> commandDecider,
    required EventReducer<TEvent, TState> eventReducer,
    EventStorage<TEvent>? eventStorage,
  }) async {
    final aggregate =
        AggregateFullyGeneric<TCommand, TEvent, TState, TOption>._(
          initialState: initialState,
          optionFinder: optionFinder,
          commandDecider: commandDecider,
          eventReducer: eventReducer,
          eventStorage: eventStorage ?? InMemoryEventStorage(),
        );
    await aggregate._replayStoredEvents();
    return aggregate;
  }

  /// Creates an aggregate that starts in [state] without reading [eventStorage].
  /// Only events appended from now on are applied.
  ///
  /// [state] should already reflect the events in [eventStorage].
  /// Otherwise loading the same storage later yields a different state.
  static AggregateFullyGeneric<TCommand, TEvent, TState, TOption>
  resume<TCommand, TEvent, TState, TOption>({
    required TState state,
    OptionFinder<TOption, TState>? optionFinder,
    required CommandDecider<TCommand, TEvent, TState> commandDecider,
    required EventReducer<TEvent, TState> eventReducer,
    EventStorage<TEvent>? eventStorage,
  }) => AggregateFullyGeneric<TCommand, TEvent, TState, TOption>._(
    initialState: state,
    optionFinder: optionFinder,
    commandDecider: commandDecider,
    eventReducer: eventReducer,
    eventStorage: eventStorage ?? InMemoryEventStorage(),
  );

  Future<void> _replayStoredEvents() async {
    await for (final event in eventStorage.readAll()) {
      _state = _eventReducer.reduce(event, _state);
    }
  }

  Iterable<TOption> findOptions() {
    return _optionFinder?.find(_state) ?? [];
  }

  /// Queues [command] behind all previously processed commands.
  /// Once its turn comes, decides it, stores the resulting events with a
  /// single [EventStorage.appendAll] and only then updates the state.
  Future<TState> process(TCommand command) async {
    if (_isClosed) {
      throw StateError(_closedMessage);
    }

    return _commandQueue.run(() => _commit(command));
  }

  Future<TState> _commit(TCommand command) async {
    final events = _commandDecider.decide(command, _state);

    final reductions = <Reduction<TEvent, TState>>[];
    var runningState = _state;
    for (final event in events) {
      final previousState = runningState;
      runningState = _eventReducer.reduce(event, runningState);
      reductions.add(
        Reduction(
          event: event,
          previousState: previousState,
          state: runningState,
        ),
      );
    }

    // commit transaction: storage first, then state, then notifications
    await eventStorage.appendAll([
      for (final reduction in reductions) reduction.event,
    ]);

    _state = runningState;

    for (final reduction in reductions) {
      _eventsController.add(reduction);
    }

    return _state;
  }

  /// Finishes all queued commands, then closes [events].
  /// Afterwards [process] fails with a [StateError].
  Future<void> close() async {
    _isClosed = true;
    await _commandQueue.idle;
    await _eventsController.close();
  }
}
