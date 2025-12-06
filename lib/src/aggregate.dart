import 'package:replay/src/command/command_decider.dart';
import 'package:replay/src/event/event_reducer.dart';
import 'package:replay/src/event_store/event_store.dart';
import 'package:replay/src/event_store/in_memory_event_store.dart';

typedef OnEventReduced<TEvent, TState> =
    void Function(TEvent event, TState previousState, TState updatedState);

class Aggregate<TCommand, TEvent, TState> {
  final CommandDecider<TCommand, TEvent, TState> _commandDecider;
  final EventReducer<TEvent, TState> _eventReducer;
  final OnEventReduced<TEvent, TState>? _onEventReduced;

  TState _stateSnapshot;
  TState get currentState => _stateSnapshot;

  EventStore<TEvent> _eventStore;
  EventStore<TEvent> get eventStore => _eventStore;

  Aggregate({
    required TState initialState,
    required CommandDecider<TCommand, TEvent, TState> commandDecider,
    required EventReducer<TEvent, TState> eventReducer,
    EventStore<TEvent>? eventStore,
    bool replayStoredEvents = false,
    OnEventReduced<TEvent, TState>? onEventReduced,
  }) : _stateSnapshot = initialState,
       _commandDecider = commandDecider,
       _eventReducer = eventReducer,
       _eventStore = eventStore ?? InMemoryEventStore(),
       _onEventReduced = onEventReduced {
    if (replayStoredEvents) _replayStoredEvents();
  }

  void replay({
    required TState initialState,
    required EventStore<TEvent> eventStore,
  }) {
    _stateSnapshot = initialState;
    _eventStore = eventStore;
    _replayStoredEvents();
  }

  void _replayStoredEvents() {
    final events = _eventStore.iterable;
    if (events.isNotEmpty) {
      for (final event in events) {
        final previousState = _stateSnapshot;
        _stateSnapshot = _eventReducer.reduce(event, _stateSnapshot);

        _onEventReduced?.call(event, previousState, _stateSnapshot);
      }
    }
  }

  TState process(TCommand command) {
    final events = _commandDecider.decide(command, _stateSnapshot);

    final reductions = <({TEvent event, TState updatedState})>[];
    try {
      var runningState = _stateSnapshot;
      for (final event in events) {
        runningState = _eventReducer.reduce(event, runningState);
        reductions.add((event: event, updatedState: runningState));
      }
    } catch (_) {
      // rollback transaction, i.e. do not commit
      rethrow;
    }

    // commit transaction
    for (final reduction in reductions) {
      final previousState = _stateSnapshot;
      _stateSnapshot = reduction.updatedState;

      _eventStore.append(reduction.event);

      _onEventReduced?.call(reduction.event, previousState, _stateSnapshot);
    }

    return _stateSnapshot;
  }
}
