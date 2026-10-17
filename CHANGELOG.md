## 2.0.0

- update dart SDK constraint to `^3.13.5`
- remove the `Map` constructor parameters of `ComposableCommandDecider`, `ComposableEventReducer` and `ComposableOptionFinder`; use `register`
- dispatch composable deciders and reducers by subtype (`is T`); the first matching registration wins
- throw `StateError` instead of `ArgumentError` when no registration matches a command or event

## 1.1.0

- add `OptionFinder`
- add `ComposableOptionFinder`

## 1.0.0

- export `InvalidCommandException`

## 0.0.1

- initial version
