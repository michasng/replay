## 2.0.0

- update dart SDK constraint to `^3.13.5`
- rename `AggregateFullyGeneric` to `Aggregate`; it no longer has a fourth type parameter `TOption`, so `AggregateFullyGeneric<C, E, S, O>` becomes `Aggregate<C, E, S>`
- remove `Aggregate.findOptions()` and the `optionFinder` parameter; use `optionFinder.find(aggregate.currentState)`
- remove the `Map` constructor parameters of `ComposableCommandDecider`, `ComposableEventReducer` and `ComposableOptionFinder`; use `register`
- dispatch composable deciders and reducers by subtype (`is T`); the first matching registration wins
- throw `StateError` instead of `ArgumentError` when no registration matches a command or event
- `EventStorage` is asynchronous: `readAll()` returns a `Stream` and `appendAll(List)` replaces `iterable` and `append`; `appendAll` is all-or-nothing
- `Aggregate.process` returns a `Future` and commits all events of a command with a single `appendAll`
- create aggregates with the async `Aggregate.load`; the constructor is private
- remove `replayStoredEvents` and `replay()`; `load` always replays stored events
- add `Aggregate.resume` to start from a given state without replaying stored events
- `Aggregate.process` queues commands and processes them one at a time, in arrival order
- replace `onEventReduced` with the broadcast stream `Aggregate.events` of `Reduction`; replayed events are not emitted and throwing listeners cannot affect a commit
- add `Aggregate.close()` to finish queued commands, close `events` and reject later commands with a `StateError`

### Migrating from 1.x

- `Aggregate(...)` / `AggregateFullyGeneric(...)` → `await Aggregate.load(...)`; use `Aggregate.resume(...)` to start from a known state without replaying.
- Remove `replayStoredEvents` and `replay()` calls; `load` replays automatically.
- `aggregate.process(command)` → `await aggregate.process(command)`; it returns the new state.
- Implement `EventStorage` with `Stream<E> readAll()` and `Future<void> appendAll(List<E>)` instead of `iterable` and `append`.
- `onEventReduced` callback → listen to `aggregate.events`.
- `aggregate.findOptions()` → `optionFinder.find(aggregate.currentState)`.
- Replace `Map` constructor arguments of the composable classes with `register<T>(...)`.
- Catch `StateError` instead of `ArgumentError` for unregistered types.
- Call `await aggregate.close()` when done.

## 1.1.0

- add `OptionFinder`
- add `ComposableOptionFinder`

## 1.0.0

- export `InvalidCommandException`

## 0.0.1

- initial version
