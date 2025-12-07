An Event Sourcing framework for Dart.

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

✔️ Idempotent event processing \
✔️ Snapshotting support \
✔️ In-memory or custom event storage support \
🔜 Automatic partitioning (WIP) \
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

Finally put it all together in one `Aggregate` and call `process` on every command:

```dart
import 'package:replay/replay.dart';

final aggregate = Aggregate<BankCommand, BankEvent, BankState>(
  initialState: BankState(),
  commandDecider: ComposableCommandDecider({
    OpenAccountCommand: OpenAccountCommandDecider(),
    CloseAccountCommand: CloseAccountCommandDecider(),
    TransferMoneyCommand: TransferMoneyCommandDecider(),
  }),
  eventReducer: ComposableEventReducer({
    BalanceSetEvent: BalanceSetEventReducer(),
    BalanceUnsetEvent: BalanceUnsetEventReducer(),
  }),
  eventStorage: InMemoryEventStorage(),
);

aggregate.process(OpenAccountCommand(accountName: 'Foo', initialBalance: 100));
```

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
  - Use "snapshots" of the state for optimized queries (Command Query Responsibility Segregation - CQRS)
- Idempotent: Processing the same event repeatedly always results in the same state
- Atomic: Either processing succeeds completely or nothing changes

### Aggregate

An aggregate acts as a **consistency boundary** — grouping a command's events into **atomic** (all-or-nothing) operations. It enforces **invariants** by validating commands against the state, which is derived from past events. Valid commands produce new events, updating the aggregate. These events are stored immutably to enable auditability.
