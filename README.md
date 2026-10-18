# Replay

Event Sourcing framework for Dart to build auditable apps with immutable events.

## Why Event Sourcing?

Event sourcing is the pinnacle of event driven architectures!

It records all changes to an application's state as a sequence of immutable events, rather than storing only the current state.

This provides you with a complete audit log by design and enables temporal queries ("show me last Tuesday's state") by allowing you to deterministically _replay_ past events.

Event Sourcing powers undo/redo in apps, audit trails in banking, and Git’s commit history.

## Installation

```bash
dart pub add replay
```

## Features

✔️ Deterministic replay \
✔️ Atomic, queued command processing \
✔️ In-memory or custom asynchronous event storage \
✔️ Event stream for building read models \
✔️ Sound null safety \
✔️ 100 % test coverage \
✔️ No dependencies

## Usage

See [example](https://pub.dev/packages/replay/example).

Start by defining immutable classes for:

- the state of an aggregate
- events with a common interface
- commands with a common interface

Then create classes that implement `CommandDecider` and `EventReducer`.

Finally put it all together in one `Aggregate` and `await` `process` for every command. It returns the new state; commands are queued and handled one at a time:

```dart
import 'package:replay/replay.dart';

final aggregate = await Aggregate.load(
  initialState: BankState(),
  commandDecider: ComposableCommandDecider<BankCommand, BankEvent, BankState>()
    ..register<OpenAccountCommand>(OpenAccountCommandDecider())
    ..register<CloseAccountCommand>(CloseAccountCommandDecider())
    ..register<TransferMoneyCommand>(TransferMoneyCommandDecider()),
  eventReducer: ComposableEventReducer<BankEvent, BankState>()
    ..register<BalanceSetEvent>(BalanceSetEventReducer())
    ..register<BalanceUnsetEvent>(BalanceUnsetEventReducer()),
  eventStorage: InMemoryEventStorage(),
);

await aggregate.process(OpenAccountCommand(accountName: 'Foo', initialBalance: 100));

await aggregate.close();
```

`Aggregate.load` replays all stored events. To skip the replay, start from a state you already know with the synchronous `Aggregate.resume`; it must match the stored events.

Read the current state via `aggregate.currentState`. To react to committed events (e.g. to maintain read models), listen to the broadcast `aggregate.events` stream of `Reduction`s.

### Event storage

Implement `EventStorage` to persist events. `readAll` streams all events in append order and `appendAll` stores a command's events all-or-nothing. Each storage belongs to exactly one aggregate. `InMemoryEventStorage` is the default.

## Concepts

### Commands vs. Events

Both commands and events describe actions from a business perspective, but that's where their similarities end.

Commands:

- Request an action in imperative mood ("send message")
- Originate externally
- Immutable once issued
- Can be invalid/rejected (require validation)
- May produce 0-N events when processed

Events:

- Record completed actions in past tense ("message sent")
- Internally-generated facts
- Always immutable (cannot be modified) & append-only
- Can never be invalid
- Used to construct the application state (single source of truth)
- Deterministic: Replaying the same events always results in the same state
- Atomic: Either processing succeeds completely or nothing changes

### Aggregate

An aggregate acts as a **consistency boundary** — grouping a command's events into **atomic** (all-or-nothing) operations. It enforces **invariants** by validating commands against the state, which is derived from past events. Valid commands produce new events, updating the aggregate. These events are stored immutably to enable auditability.

### Options: Discovering Valid Commands

Sometimes you don’t want to guess whether a command will succeed — you want to know all valid commands, given the current state. \
This is addressed via a unique (but optional) concept: **Options**. They are independent of the `Aggregate`.

Options represent potential commands that could be processed for the current state of an aggregate. \
Just as events are derived from commands, commands are derived from options. \
Unlike commands, options stem from inspecting the aggregate's state rather than being issued externally. \
A single option can represent multiple (potentially infinitely many) commands by specifying the constraints that all commands of that type must satisfy.

To implement this, create an `OptionFinder` for your aggregate. It examines the current state and returns all options:

```dart
final optionFinder = ComposableOptionFinder<BankOption, BankState>()
  ..register<OpenAccountOption>(OpenAccountOptionFinder())
  ..register<CloseAccountOption>(CloseAccountOptionFinder())
  ..register<TransferMoneyOption>(TransferMoneyOptionFinder());

final options = optionFinder.find(aggregate.currentState);
```

This enables automated systems to query all valid commands, empowering UIs where every offered action is guaranteed to succeed.
