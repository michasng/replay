# Replay

An event sourcing framework: state is never stored directly, only derived by replaying an ordered sequence of immutable events.

## Language

### Writing

**Command**:
A request for an action, phrased in the imperative mood, that may be rejected.
_Avoid_: Action, request, intent

**Event**:
An immutable fact, phrased in the past tense, recording that something happened. Events carry no identity of their own; only their order matters.
_Avoid_: Message, change

**Aggregate**:
A consistency boundary that decides whether a command is valid against its current state and turns valid commands into events. It is the only writer of its events.
_Avoid_: Entity, model, store

**Commit**:
The all-or-nothing recording of every event produced by a single command. Either all of them are stored and applied to state, or none are.
_Avoid_: Transaction, save

### Reading

**State**:
The value obtained by applying every event, in order, to an initial value. Commands are validated against it, and callers may read it directly.
_Avoid_: Snapshot, current snapshot

**Replay**:
Rebuilding state by applying stored events, in order, to an initial state.
_Avoid_: Rehydrate, restore

**Projection**:
A read-only view derived from events outside the aggregate, shaped for a particular query. It is never used to validate commands and can be discarded and rebuilt.
_Avoid_: Read model, view, snapshot

### Discovery

**Option**:
A description of a family of commands that would currently be valid, derived from state rather than issued by a caller.
_Avoid_: Action, suggestion, available command
