# Events have no identity; one aggregate per event storage

Replay targets a single writer: each event storage is written by exactly one `Aggregate`, and events are fully generic values with no ID, timestamp, or position — storage only has to preserve append order. We chose this over the conventional event-sourcing setup (numbered streams with an expected-position check on append) to keep events and storage implementations maximally simple and flexible, accepting that multiple writers on one storage are unsupported.

## Consequences

- No optimistic concurrency check: two aggregates appending to the same storage can commit conflicting events, and this is not detected.
- No snapshots: without event positions there is no way to say which events a saved state already reflects, so replay always starts from the beginning.
- No de-duplication: replay is deterministic, but appending the same event twice applies it twice.
- Commands to a single aggregate are processed one at a time, which is what makes the single-writer assumption hold within a process.

Revisiting any of these requires introducing event positions first.
