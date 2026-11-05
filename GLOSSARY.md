# Snappy Tennis Scoreboard

A tennis scoreboard that players keep on their Apple Watch during a match, plus optional apps on iPhone and iPad.

## Apps

**Watch App**:
The Apple Watch app that keeps score on court. It is complete on its own and never needs another app installed.
_Avoid_: Main app, scorer

**Companion App**:
The optional iPhone/iPad app that adds extra features on top of the Watch App. It never replaces the Watch App.
_Avoid_: Mobile app, phone app, iOS app

## Scoring

**Match**:
A competitive game of tennis between two players, played to a set number of sets under chosen rules (tiebreak, deuce, server).
_Avoid_: Game (a game is one unit within a set)

**Player**:
One of the two sides in a Match, identified only by a name and a colour. Players are not saved profiles.
_Avoid_: Profile, opponent, user

**Play On**:
Continuing a finished Match as a longer one (1 set → 3 sets, 3 sets → 5 sets). It is still the same Match, not a new one.
_Avoid_: Continue, extend, rematch

**Unfinished Match**:
A Match that stopped before anyone won it, for example a rain-out. It is kept in Match History with the score at the point it stopped.
_Avoid_: Abandoned, incomplete, cancelled

**Practice Session**:
Casual play scored without match rules mattering. It is never kept in Match History.
_Avoid_: Training, training mode

**Scorer**:
The one device that keeps score for a Match: whichever device started it. Only the Scorer can change the score.
_Avoid_: Host, controller

**Live Scoreboard**:
A read-only view of a Match in progress, shown on a device that is not the Scorer.
_Avoid_: Mirror, spectator view

**Match History**:
The record of every point of every Match, finished or Unfinished, shared across all of a user's devices.
_Avoid_: Results, log
