# Project Guidelines

Dart without external dependencies (except lints + test).

## Coding Principles

Always consider these principles.
Write out their names when discussing their trade-offs.

- **You Aren't Gonna Need It (YAGNI)**: Implement only what is required now
- **Low Coupling**: Define contracts with abstractions
- **High Cohesion**: Bundle functionality; prefer local over global scope
- **Separation of Concerns (SoC)**: Separate structure, behavior, and persistence. One entity per file
- **Single Responsibility (SRP)**: Each function, component, or module has one reason to change. Small components, one job each
- **Open/Closed (OCP)**: Extend behavior without modifying existing code
- **Dependency Inversion (DIP)**: Depend on abstractions, not concretions
- **Interface Segregation (ISP)**: Depend on minimal interfaces
- **Inversion of Control (IoC)**: Inject dependencies; never construct services inside the code that uses them
- **Command-Query Separation (CQS)**: A method either has a side-effect or returns data, but never both; the name indicates which
- **Composition over Inheritance**: Prefer "has a" over "is a"
- **Deep Modules**: Hide complexity behind simple interfaces
- **Self-Documenting Code**: Expressive naming, include units, no abbreviations (e.g. `timeoutSeconds`), avoid comments
- **Flat Control Flow**: Use early returns to avoid nesting

## Code Style

- Use American English
- One unit (class or function) per file; name files after their unit in `snake_case`, e.g. `do_something.dart` would contain a function called `doSomething` (and maybe some constants)
- Export public units through the folder's `index.dart`; keep private implementation details in `lib/src/internal/`
- Strict typing, sound null-safety; no `dynamic`, no not-null assertions (`!`) — model types honestly
- Never suppress analyzer errors or lints (`// ignore:`, `// ignore_for_file:`)
- No type casts (`as`) unless there is no better option; if unavoidable, add a short comment explaining why
- No magic numbers or strings; extract them to named constants or enums
- No dead code, commented-out blocks, or leftover `TODO`s

## Testing

- All logic must be unit tested in `test/`, mirroring the folder structure of `lib/src/` (`<unit>_test.dart`); add or update tests with every behavior change
- Do not unit test declarations, when the test only duplicates their values
- One `group` block at the top per unit under test
- Describe scenarios with non-technical `given|when <scenario>` groups or test names
- Follow Arrange–Act–Assert
- Keep a minimal shared setup
- Don't use mocking libraries; pass simple hand-written stubs, fakes or spies (e.g. `<unit>_mock.dart`) directly to the tested code (dependency injection)
- Never use arbitrary waits in tests; await the specific concrete future the code under test is waiting on

## Workflow

- Read a file before editing it; verify assumptions with tests rather than guessing
- Atomic changes: reduce every task to the smallest change that makes sense and leaves the package usable
- Run `dart fix --apply` and `dart format .` to auto-fix lint and formatting issues before staging
- Verify every change with `dart analyze --fatal-infos` and `dart test`
- Keep responses and diffs minimal; skip restating unchanged code
- Suggest a non-technical commit message
  - Tiny first line, no commas or bullet points
  - Optionally a blank line, then more context if it helps

## Agent skills

### Issue tracker

Issues and specs are tracked as local markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default canonical labels (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`), recorded as `Status:` lines. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
