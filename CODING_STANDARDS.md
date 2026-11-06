# Coding standards

Judgement calls for review. Anything the compiler or `scripts/check.sh` catches is left to them.

## Domain language

- Names of types, functions, user-facing text and doc comments use the terms in `GLOSSARY.md`. A word on a term's _Avoid_ list is a finding, e.g. `PhoneScorer` (should be `Scorer`) or "rematch" (should be Play On).
- A new domain concept gets a GLOSSARY.md entry in the same change.

## Where code lives

- Scoring rules and anything both apps share live in `Packages/TennisScoring`. The Watch App and Companion App hold only their views and platform glue (WatchConnectivity, UserDefaults, haptics).
- The Watch App is complete on its own (`docs/adr/0001`). Watch App features must keep working with no Companion App installed.
- A Practice Session is never saved to Match History.

## Tests

- Package logic is tested with Swift Testing through its public interface, at seams agreed before writing the tests. Expected values come from worked tennis examples, not from re-running the code's own arithmetic.
- Every control a UI test or screenshot tour taps has an `accessibilityIdentifier` named `kind.name`, e.g. `button.playOn` or `score.player1`.

## Comments

- Each type has a one-line `///` saying what it is in domain terms.
- Other comments say why, not what, e.g. "Kept courtside, so the screen stays on".

## Concurrency

- App targets default to main-actor isolation. Delegate callbacks that arrive off the main thread (such as `WCSessionDelegate`) are `nonisolated` and hop back with `Task { @MainActor in … }`.
