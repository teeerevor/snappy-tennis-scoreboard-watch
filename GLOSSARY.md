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

**Match in Progress**:
The one Match a Scorer is keeping right now, with no winner yet. It stays in progress when the app closes, until it is won, a New Match replaces it, or the day of its last point ends at 2am.
_Avoid_: Current match, active match, live match

**Unfinished Match**:
A Match that stopped being in progress before anyone won it: replaced by a New Match, or left until the day ended, for example after a rain-out. It is kept in Match History with the score at the point it stopped.
_Avoid_: Abandoned, incomplete, cancelled

**Practice Session**:
Casual play scored without match rules mattering. It is never kept in Match History. On the Apple Watch its count stays when the app closes, until the day of tennis ends at 2am.
_Avoid_: Training, training mode

**Scorer**:
The one device that keeps score for a Match: whichever device started it. Only the Scorer can change the score.
_Avoid_: Host, controller

**Live Scoreboard**:
A read-only view of a Match in Progress, shown on a device that is not the Scorer.
_Avoid_: Mirror, spectator view

**Watch Sync**:
The Companion App hands a Match it set up to the Apple Watch, which starts it and becomes its Scorer, then shows that Match's Live Scoreboard full screen.
_Avoid_: Send to watch, mirroring

**Match History**:
The record of every point of every Match scored on a device, finished or Unfinished. Each device keeps its own, and the Apple Watch also sends its Matches to the paired iPhone's, so they can be found and shared there.
_Avoid_: Results, log

**Scorecard**:
A Match's result drawn as a card (Players, set scores, finished or Unfinished) for sharing as an image.
_Avoid_: Receipt, summary

**Continue Match**:
Going back to scoring this device's Match in Progress, including after the app was closed. Not Play On, which makes a finished Match longer; when the Apple Watch is the Scorer, the Companion App goes back to its Live Scoreboard instead.
_Avoid_: Resume
