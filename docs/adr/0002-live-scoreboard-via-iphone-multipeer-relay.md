# Live Scoreboard reaches the iPad through an iPhone relay over Multipeer

Exactly one device, the Scorer, keeps score for a Match, and every other device shows a read-only Live Scoreboard. An Apple Watch can only talk to its paired iPhone, so a watch-scored Match reaches an iPad as watch → iPhone (WatchConnectivity) → iPad (Multipeer Connectivity, over Bluetooth / peer-to-peer Wi-Fi). We chose this because it needs no internet (tennis courts usually have none), costs nothing to run, and updates instantly.

## Considered Options

- **iCloud, written by the watch**: no iPhone needed, but needs internet on both devices, lags by a few seconds, and only works on the same Apple ID. It is the likely v2 option, because it reuses the Match History iCloud sync.
- **Our own server**: real-time and allows remote spectators, but has hosting cost and needs accounts. Only worth it for remote spectating.
- **The iPad keeps score itself**: also supported, and needs no relay.

## Consequences

- iOS stops Multipeer connections in the background, so the Companion App must stay open courtside, with the screen kept awake, while relaying.
- One Scorer per Match means the relay only ever sends data one way, so there are no conflicting edits to merge.
- Watch Sync runs the other way only to hand over a Match: the iPhone sends the Match setup to the watch, and from then on the watch is the Scorer and only score updates flow back. The single direction of score data still holds.
