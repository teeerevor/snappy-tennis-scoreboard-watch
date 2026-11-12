# Watch Matches are kept in the iPhone's Match History

The Watch App has no Match History screen, and Scorecards are shared from the Companion App, so a Match scored on the Apple Watch was saved only where nobody could see it. Now the watch sends every change to a Match (the full record, every point) to the paired iPhone, and the Companion App saves it in its own Match History. Match History already on the watch is sent once, the first time the watch finds the Companion App installed.

Each update goes by `sendMessage` when the iPhone is reachable, which is instant, and the Companion App replies once it has saved it. Otherwise, or if that fails, it goes by `transferUserInfo`, which the system queues and delivers even when the Companion App isn't running. The queue alone wasn't enough: the system can hold transfers back for minutes, and the simulator often doesn't deliver them at all.

The watch keeps a list of the Matches the Companion App hasn't confirmed (by reply or by a finished transfer) in UserDefaults. It sends them all again whenever the iPhone becomes reachable, so a Match isn't lost when the Watch App closes or the iPhone is out of range.

## Consequences

- Only the latest version of a Match is worth sending, so a new update cancels any for the same Match still waiting in the queue.
- A Match can arrive more than once. A saved Match never replaces a later version of itself on the iPhone, so a duplicate or a late update can't take points away.
- Data still only goes one way, from the Scorer, so there is nothing to merge.
- iCloud sync of Match History (see 0002) would replace this.
