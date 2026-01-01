import 'package:replay/src/command/command_decider.dart';
import 'package:replay/src/event/event_reducer.dart';
import 'package:replay/src/event_storage/event_storage.dart';
import 'package:replay/src/event_storage/in_memory_event_storage.dart';
import 'package:replay/src/option/option_finder.dart';

typedef OnEventReduced<TEvent, TState> =
    void Function(TEvent event, TState previousState, TState updatedState);

/// Sets / Omits optional generic parameters.
/// Mainly exists for backwards compatibility.
typedef Aggregate<TCommand, TEvent, TState> =
    AggregateFullyGeneric<TCommand, TEvent, TState, dynamic>;

class AggregateFullyGeneric<TCommand, TEvent, TState, TOption> {
  final OptionFinder<TOption, TState>? _optionFinder;
  final CommandDecider<TCommand, TEvent, TState> _commandDecider;
  final EventReducer<TEvent, TState> _eventReducer;
  final OnEventReduced<TEvent, TState>? _onEventReduced;

  TState _stateSnapshot;
  TState get currentState => _stateSnapshot;

  EventStorage<TEvent> _eventStorage;
  EventStorage<TEvent> get eventStorage => _eventStorage;

  AggregateFullyGeneric({
    required TState initialState,
    OptionFinder<TOption, TState>? optionFinder,
    required CommandDecider<TCommand, TEvent, TState> commandDecider,
    required EventReducer<TEvent, TState> eventReducer,
    EventStorage<TEvent>? eventStorage,
    bool replayStoredEvents = false,
    OnEventReduced<TEvent, TState>? onEventReduced,
  }) : _stateSnapshot = initialState,
       _optionFinder = optionFinder,
       _commandDecider = commandDecider,
       _eventReducer = eventReducer,
       _eventStorage = eventStorage ?? InMemoryEventStorage(),
       _onEventReduced = onEventReduced {
    if (replayStoredEvents) _replayStoredEvents();
  }

  void replay({
    required TState initialState,
    required EventStorage<TEvent> eventStorage,
  }) {
    _stateSnapshot = initialState;
    _eventStorage = eventStorage;
    _replayStoredEvents();
  }

  void _replayStoredEvents() {
    final events = _eventStorage.iterable;
    if (events.isNotEmpty) {
      for (final event in events) {
        final previousState = _stateSnapshot;
        _stateSnapshot = _eventReducer.reduce(event, _stateSnapshot);

        _onEventReduced?.call(event, previousState, _stateSnapshot);
      }
    }
  }

  Iterable<TOption> findOptions() {
    return _optionFinder?.find(_stateSnapshot) ?? [];
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

      _eventStorage.append(reduction.event);

      _onEventReduced?.call(reduction.event, previousState, _stateSnapshot);
    }

    return _stateSnapshot;
  }
}
