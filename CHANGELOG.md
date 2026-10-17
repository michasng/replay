## 2.0.0

- update dart SDK constraint to `^3.13.5`
- remove the `Map` constructor parameters of `ComposableCommandDecider`, `ComposableEventReducer` and `ComposableOptionFinder`; use `register`
- dispatch composable deciders and reducers by subtype (`is T`); the first matching registration wins
- throw `StateError` instead of `ArgumentError` when no registration matches a command or event
- `EventStorage` is asynchronous: `readAll()` returns a `Stream` and `appendAll(List)` replaces `iterable` and `append`; `appendAll` is all-or-nothing
- `Aggregate.process` returns a `Future` and commits all events of a command with a single `appendAll`
- create aggregates with the async `AggregateFullyGeneric.load`; the constructor is private
- remove `replayStoredEvents` and `replay()`; `load` always replays stored events
- add `AggregateFullyGeneric.resume` to start from a given state without replaying stored events
- `Aggregate.process` queues commands and processes them one at a time, in arrival order
- replace `onEventReduced` with the broadcast stream `Aggregate.events` of `Reduction`; replayed events are not emitted and throwing listeners cannot affect a commit
- add `Aggregate.close()` to finish queued commands, close `events` and reject later commands with a `StateError`

## 1.1.0

- add `OptionFinder`
- add `ComposableOptionFinder`

## 1.0.0

- export `InvalidCommandException`

## 0.0.1

- initial version
